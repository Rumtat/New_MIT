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

    // ✅ ใช้เป็น instance เดียว + forward change ให้ UI refresh ทันที
    let history = ScanHistory()

    private var cancellables = Set<AnyCancellable>()

    // Services
    private let riskService = RiskService(repository: FirebaseScamRepository())
    private let urlAnalyzer = UrlRiskAnalyzer()
    private let smsAnalyzer = SmsRiskAnalyzer()
    private let phoneValidator = PhoneValidator()

    // ✅ Sprint C: Bank via Firestore
    private let bankFS = BankFirestoreService()

    init() {
        // ✅ Forward nested ObservableObject -> View refresh ทันทีเมื่อ history เปลี่ยน
        history.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Public helpers (QR normalize)

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

    // MARK: - Normalization

    func normalizedInputForScan() -> String {
        switch selectedType {
        case .phone:
            return phoneDigits

        case .bank:
            if bankMode == .byAccount {
                // ⚠️ สำคัญ: ห้ามตัด 0 นำหน้า (Firestore docID มี leading zeros)
                // ดังนั้น "กรองเฉพาะตัวเลข" แต่คงลำดับเดิมไว้
                let raw = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
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

    // MARK: - Bank (Sprint C)

    func runBankScan() async -> ScanResult? {
        let input = normalizedInputForScan()
        guard !input.isEmpty else { errorMessage = "กรุณากรอกข้อมูล"; return nil }

        isLoading = true
        errorMessage = nil

        do {
            if bankMode == .byAccount {
                // 1) Firestore blacklist by docID
                let entry = try await bankFS.fetchBlacklistByAccount(input)

                // 2) user reports (optional)
                let reports = await bankFS.fetchReportsByAccount(inputText.trimmingCharacters(in: .whitespacesAndNewlines))

                isLoading = false

                if let e = entry {
                    var reasons: [String] = []
                    reasons.append(e.bank_name.map { "ธนาคาร: \($0)" } ?? "พบใน bank_blacklist")
                    reasons.append(e.name.map { "ชื่อผู้รับ: \($0)" } ?? "—")
                    reasons.append(contentsOf: e.reasons ?? [])
                    reasons.append(contentsOf: reports)

                    var result = ScanResult(type: .bank, input: input, level: e.riskLevel, reasons: reasons.uniquedPreservingOrder())
                    result.bankName = e.bank_name
                    result.ownerName = e.name
                    history.add(result)
                    return result
                }

                // ถ้าไม่พบ blacklist แต่มีรายงาน
                if !reports.isEmpty {
                    let r = ScanResult(type: .bank, input: input, level: .medium, reasons: reports.uniquedPreservingOrder())
                    history.add(r)
                    return r
                }

                let ok = ScanResult(type: .bank, input: input, level: .low, reasons: ["ไม่พบใน bank_blacklist และไม่พบรายงานผู้ใช้"])
                history.add(ok)
                return ok

            } else {
                // byName (exact match)
                let matches = try await bankFS.fetchBlacklistByName(input)

                isLoading = false

                if matches.isEmpty {
                    let ok = ScanResult(type: .bank, input: input, level: .low, reasons: ["ไม่พบชื่อใน bank_blacklist"])
                    history.add(ok)
                    return ok
                }

                // เลือกผลที่เสี่ยงที่สุด
                let worst = matches.max(by: { $0.riskLevel < $1.riskLevel }) ?? matches[0]

                var reasons: [String] = []
                reasons.append("พบชื่อใน bank_blacklist จำนวน \(matches.count) รายการ")
                reasons.append(worst.bank_name.map { "ธนาคาร: \($0)" } ?? "—")
                reasons.append(worst.name.map { "ชื่อผู้รับ: \($0)" } ?? "—")
                reasons.append(contentsOf: worst.reasons ?? [])

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

    // MARK: - Phone

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

        let dbResult = await riskService.scan(type: .phone, input: cleaned)

        var reasons = dbResult.reasons
        var level = dbResult.level

        if let meta = phoneValidator.validate(cleaned) {
            reasons.append("ประเภท: \(meta.typeDescription)")
            reasons.append("เครือข่าย: \(meta.carrier)")
            reasons.append("พื้นที่: \(meta.origin)")

            if meta.isHighRiskPattern {
                level = max(level, .medium)
                reasons.append("รูปแบบหมายเลขผิดปกติ (เลขซ้ำ/คล้ายสร้างขึ้น)")
            }
            if meta.isVerifiedService {
                level = .low
                reasons.append("เป็นเบอร์หน่วยงานที่อยู่ใน whitelist")
            }
        }

        isLoading = false
        let result = ScanResult(type: .phone, input: cleaned, level: level, reasons: reasons.uniquedPreservingOrder())
        history.add(result)
        return result
    }

    // MARK: - Generic scan (URL / QR / SMS)

    func runScan() async -> ScanResult? {
        let input = normalizedInputForScan()
        guard !input.isEmpty else { errorMessage = "กรุณากรอกข้อมูล"; return nil }

        isLoading = true
        errorMessage = nil

        switch selectedType {
        case .url, .qr:
            let analysis = urlAnalyzer.analyze(input)
            let dbResult = await riskService.scan(type: .url, input: analysis.normalizedUrl)

            let finalLevel = max(analysis.level, dbResult.level)
            let mergedReasons = (analysis.reasons + dbResult.reasons).uniquedPreservingOrder()

            isLoading = false
            let result = ScanResult(type: selectedType, input: analysis.normalizedUrl, level: finalLevel, reasons: mergedReasons)
            history.add(result)
            return result

        case .sms, .text:
            let sms = smsAnalyzer.analyze(input)
            var reasons = sms.reasons
            var finalLevel = sms.level

            if let firstUrl = sms.extractedUrls.first {
                let urlAnalysis = urlAnalyzer.analyze(firstUrl)
                let dbResult = await riskService.scan(type: .url, input: urlAnalysis.normalizedUrl)

                finalLevel = max(finalLevel, max(urlAnalysis.level, dbResult.level))
                reasons.append("ลิงก์ที่พบ: \(urlAnalysis.normalizedUrl)")
                reasons.append(contentsOf: urlAnalysis.reasons)
                reasons.append(contentsOf: dbResult.reasons)
            }

            isLoading = false
            let result = ScanResult(type: .sms, input: input, level: finalLevel, reasons: reasons.uniquedPreservingOrder())
            history.add(result)
            return result

        default:
            let r = await riskService.scan(type: selectedType, input: input)
            isLoading = false
            history.add(r)
            return r
        }
    }
}
