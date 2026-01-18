//
//  ScanViewModel.swift
//  BYB_mit02
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ScanViewModel: ObservableObject {

    @Published var selectedType: ScanType = .url
    @Published var inputText: String = ""
    @Published var phoneDigits: String = ""
    @Published var fullNameInput: String = ""
    @Published var bankMode: BankSearchMode = .byAccount
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let history = ScanHistory()

    private var cancellables = Set<AnyCancellable>()

    private let repository = FirebaseScamRepository()
    private lazy var riskService = RiskService(repository: repository)

    private let urlAnalyzer = UrlRiskAnalyzer()
    private let smsAnalyzer = SmsRiskAnalyzer()
    private let phoneValidator = PhoneValidator()

    // Bank Firestore
    private let bankFS = BankFirestoreService()

    init() {
        // ✅ ลบแล้วหายทันที (forward nested objectWillChange)
        history.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Helpers (URL normalize)

    func normalizeUrlInput(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "" }

        if s.lowercased().hasPrefix("http://") || s.lowercased().hasPrefix("https://") {
            return s
        }
        if s.contains(".") && !s.contains(" ") {
            return "https://" + s
        }
        return s
    }

    func looksLikeUrl(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.lowercased().hasPrefix("http://") || s.lowercased().hasPrefix("https://") { return true }
        if s.contains(".") && !s.contains(" ") { return true }
        return false
    }

    func normalizedInputForScan() -> String {
        switch selectedType {
        case .phone:
            return phoneDigits.trimmingCharacters(in: .whitespacesAndNewlines)

        case .bank:
            if bankMode == .byAccount {
                let raw = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                // ⚠️ รักษา 0 นำหน้า
                return raw.filter { $0.isNumber }
            } else {
                return fullNameInput
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }

        case .url:
            return normalizeUrlInput(inputText)

        default:
            return inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func clearAllInputs() {
        inputText = ""
        phoneDigits = ""
        fullNameInput = ""
        errorMessage = nil
    }

    // MARK: - Bank (Firestore + heuristic + noData gray)

    func runBankScan() async -> ScanResult? {
        let input = normalizedInputForScan()
        guard !input.isEmpty else { errorMessage = "กรุณากรอกข้อมูล"; return nil }

        isLoading = true
        errorMessage = nil

        do {
            if bankMode == .byAccount {
                let entry = try await bankFS.fetchBlacklistByAccount(input)

                // เสริม: รายงานผู้ใช้
                let reports = await bankFS.fetchReportsByAccount(inputText.trimmingCharacters(in: .whitespacesAndNewlines))

                isLoading = false

                // heuristic
                var heuristic: [String] = []
                heuristic.append("Heuristic: ตรวจรูปแบบเลขบัญชี")
                heuristic.append("• ความยาว: \(input.count) หลัก")
                if input.count < 8 { heuristic.append("• ความยาวสั้นผิดปกติ") }
                if Set(input).count <= 2 { heuristic.append("• เลขซ้ำ/แพทเทิร์นแปลก (น่าสงสัย)") }

                if let e = entry {
                    var reasons: [String] = []
                    reasons.append(e.bank_name.map { "ธนาคาร: \($0)" } ?? "พบใน bank_blacklist")
                    reasons.append(e.name.map { "ชื่อผู้รับ: \($0)" } ?? "—")
                    reasons.append(contentsOf: e.reasons ?? [])
                    reasons.append(contentsOf: reports)

                    // แสดง heuristic ต่อท้ายด้วย
                    reasons.append(contentsOf: heuristic)

                    var result = ScanResult(type: .bank, input: input, level: e.riskLevel, reasons: reasons.uniquedPreservingOrder())
                    result.bankName = e.bank_name
                    result.ownerName = e.name
                    history.add(result)
                    return result
                }

                // ✅ ไม่พบในฐานข้อมูล -> เทา + แสดง heuristic
                var noDataReasons = [RiskService.noDataReason]
                noDataReasons.append(contentsOf: reports)
                noDataReasons.append(contentsOf: heuristic)

                let result = ScanResult(type: .bank, input: input, level: .low, reasons: noDataReasons.uniquedPreservingOrder())
                history.add(result)
                return result

            } else {
                // byName
                let matches = try await bankFS.fetchBlacklistByName(input)

                isLoading = false

                var heuristic: [String] = []
                heuristic.append("Heuristic: ตรวจรูปแบบชื่อ")
                heuristic.append("• จำนวนคำ: \(input.split(separator: " ").count)")
                if input.count < 6 { heuristic.append("• ชื่อสั้นผิดปกติ") }

                if matches.isEmpty {
                    // ✅ ไม่พบในฐานข้อมูล -> เทา + heuristic
                    let result = ScanResult(type: .bank, input: input, level: .low,
                                            reasons: ([RiskService.noDataReason] + heuristic).uniquedPreservingOrder())
                    history.add(result)
                    return result
                }

                let worst = matches.max(by: { $0.riskLevel < $1.riskLevel }) ?? matches[0]

                var reasons: [String] = []
                reasons.append("พบชื่อใน bank_blacklist จำนวน \(matches.count) รายการ")
                reasons.append(worst.bank_name.map { "ธนาคาร: \($0)" } ?? "—")
                reasons.append(worst.name.map { "ชื่อผู้รับ: \($0)" } ?? "—")
                reasons.append(contentsOf: worst.reasons ?? [])
                reasons.append(contentsOf: heuristic)

                var result = ScanResult(type: .bank, input: input, level: worst.riskLevel, reasons: reasons.uniquedPreservingOrder())
                result.bankName = worst.bank_name
                result.ownerName = worst.name
                history.add(result)
                return result
            }
        } catch {
            isLoading = false
            errorMessage = "เชื่อมต่อฐานข้อมูลธนาคารไม่สำเร็จ"
            return nil
        }
    }

    // MARK: - Phone (DB + heuristic + noData gray)

    func runPhoneScan() async -> ScanResult? {
        let cleaned = phoneDigits.filter { "0123456789+".contains($0) }
        guard !cleaned.isEmpty else { errorMessage = "กรอกเบอร์โทรศัพท์"; return nil }

        let numericOnly = cleaned.filter { $0.isNumber }
        if numericOnly.count < 9 {
            errorMessage = "เบอร์โทรสั้นเกินไป"
            return nil
        }

        isLoading = true
        errorMessage = nil

        let dbResult = await riskService.scanDBOnly(type: .phone, input: cleaned)

        // heuristic
        var heuristic: [String] = []
        heuristic.append("Heuristic: ตรวจรูปแบบหมายเลขโทรศัพท์")
        heuristic.append("• จำนวนตัวเลข: \(numericOnly.count)")
        if Set(numericOnly).count <= 2 { heuristic.append("• เลขซ้ำ/แพทเทิร์นแปลก (น่าสงสัย)") }

        if let meta = phoneValidator.validate(cleaned) {
            heuristic.append("• ประเภท: \(meta.typeDescription)")
            heuristic.append("• เครือข่าย: \(meta.carrier)")
            heuristic.append("• พื้นที่: \(meta.origin)")
            if meta.isHighRiskPattern { heuristic.append("• ลักษณะเข้าข่ายเบอร์สร้างขึ้น/เบอร์หลอก") }
            if meta.isVerifiedService { heuristic.append("• อยู่ใน whitelist/บริการที่เชื่อถือได้") }
        }

        isLoading = false

        if dbResult.reasons.contains(RiskService.noDataReason) {
            // ✅ ไม่พบ DB -> เทา แต่โชว์ heuristic
            let reasons = ([RiskService.noDataReason] + heuristic).uniquedPreservingOrder()
            let result = ScanResult(type: .phone, input: cleaned, level: .low, reasons: reasons)
            history.add(result)
            return result
        } else {
            // พบใน DB -> red/high (+ heuristic ต่อท้าย)
            let reasons = (dbResult.reasons + heuristic).uniquedPreservingOrder()
            let result = ScanResult(type: .phone, input: cleaned, level: dbResult.level, reasons: reasons)
            history.add(result)
            return result
        }
    }

    // MARK: - URL / QR / SMS / Text (DB + heuristic + noData gray)

    func runScan() async -> ScanResult? {
        let input = normalizedInputForScan()
        guard !input.isEmpty else { errorMessage = "กรุณากรอกข้อมูล"; return nil }

        isLoading = true
        errorMessage = nil

        switch selectedType {
        case .url, .qr:
            let analysis = urlAnalyzer.analyze(input)
            let db = await riskService.scanDBOnly(type: .url, input: analysis.normalizedUrl)

            isLoading = false

            if db.reasons.contains(RiskService.noDataReason) {
                // ✅ NO DATA (เทา) + แสดง heuristic
                var reasons = [RiskService.noDataReason]
                reasons.append(contentsOf: analysis.reasons)

                // ✅ กัน human error: ถ้า heuristic สูง ให้ขึ้นคำเตือนเด่น
                if analysis.level != .low {
                    reasons.insert("⚠️ คำเตือน: แม้ไม่มีข้อมูลในระบบ แต่รูปแบบลิงก์เข้าข่ายความเสี่ยง \(analysis.level == .high ? "สูง" : "ปานกลาง")", at: 1)
                }

                // level เก็บ heuristic เพื่อเอาไปตัดสินแบนเนอร์ แต่ UI ยังเป็นเทาเพราะมี noDataReason
                let result = ScanResult(type: selectedType, input: analysis.normalizedUrl, level: analysis.level, reasons: reasons.uniquedPreservingOrder())
                history.add(result)
                return result
            } else {
                // ✅ พบใน DB -> SCAM + heuristic
                let reasons = (db.reasons + analysis.reasons).uniquedPreservingOrder()
                let level = max(db.level, analysis.level)
                let result = ScanResult(type: selectedType, input: analysis.normalizedUrl, level: level, reasons: reasons)
                history.add(result)
                return result
            }


        case .sms, .text:
            let sms = smsAnalyzer.analyze(input)
            var reasons = sms.reasons

            // ถ้ามี URL ในข้อความ ตรวจ URL ตัวแรกด้วย URL analyzer + DB
            if let first = sms.extractedUrls.first {
                let normalized = normalizeUrlInput(first)
                let urlAnalysis = urlAnalyzer.analyze(normalized)
                let db = await riskService.scanDBOnly(type: .url, input: urlAnalysis.normalizedUrl)

                isLoading = false

                if db.reasons.contains(RiskService.noDataReason) {
                    // ✅ NO DATA (เทา) + heuristic ข้อความ + heuristic URL
                    var merged: [String] = [RiskService.noDataReason]
                    merged.append(contentsOf: reasons)
                    merged.append("ลิงก์ที่พบ: \(urlAnalysis.normalizedUrl)")
                    merged.append(contentsOf: urlAnalysis.reasons)

                    let worstHeuristic = max(sms.level, urlAnalysis.level)
                    if worstHeuristic != .low {
                        merged.insert("⚠️ คำเตือน: แม้ไม่มีข้อมูลในระบบ แต่ข้อความ/ลิงก์เข้าข่ายความเสี่ยง \(worstHeuristic == .high ? "สูง" : "ปานกลาง")", at: 1)
                    }

                    let result = ScanResult(type: .sms, input: input, level: worstHeuristic, reasons: merged.uniquedPreservingOrder())
                    history.add(result)
                    return result
                } else {
                    // ✅ พบใน DB -> SCAM + heuristic
                    var merged = db.reasons
                    merged.append(contentsOf: reasons)
                    merged.append("ลิงก์ที่พบ: \(urlAnalysis.normalizedUrl)")
                    merged.append(contentsOf: urlAnalysis.reasons)

                    let level = max(db.level, max(sms.level, urlAnalysis.level))
                    let result = ScanResult(type: .sms, input: input, level: level, reasons: merged.uniquedPreservingOrder())
                    history.add(result)
                    return result
                }
            }

            // ไม่มี URL -> NO DATA (เทา) + heuristic ข้อความ
            isLoading = false
            var merged: [String] = [RiskService.noDataReason]
            merged.append(contentsOf: reasons)

            if sms.level != .low {
                merged.insert("⚠️ คำเตือน: แม้ไม่มีข้อมูลในระบบ แต่รูปแบบข้อความเข้าข่ายความเสี่ยง \(sms.level == .high ? "สูง" : "ปานกลาง")", at: 1)
            }

            let result = ScanResult(type: .sms, input: input, level: sms.level, reasons: merged.uniquedPreservingOrder())
            history.add(result)
            return result


        default:
            // fallback: DB only + no heuristic
            let db = await riskService.scanDBOnly(type: selectedType, input: input)
            isLoading = false
            history.add(db)
            return db
        }
    }
}
