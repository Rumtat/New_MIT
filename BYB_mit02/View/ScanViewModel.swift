//
//  ScanViewModel.swift
//  BYB_mit02
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ScanViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published var selectedType: ScanType = .url
    @Published var inputText: String = ""
    @Published var phoneDigits: String = ""
    @Published var fullNameInput: String = ""
    @Published var bankMode: BankSearchMode = .byAccount

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Shared history across the app
    @Published private(set) var historyStore: ScanHistoryStore = .shared

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let scamRepository: ScamRepository = FirebaseScamRepository()
    private lazy var riskService = RiskService(repository: scamRepository)

    private let urlAnalyzer = UrlRiskAnalyzer()
    private let smsAnalyzer = SmsScanAnalyzer()
    private let phoneValidator = PhoneNumberValidator()
    private let bankRepository = BankRepository()

    init() {
        // Forward nested ObservableObject changes to refresh views immediately
        historyStore.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
    }

    // MARK: - Input helpers

    func normalizeUrlInput(_ raw: String) -> String {
        let s = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")

        guard !s.isEmpty else { return "" }

        let lower = s.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return s
        }
        if s.contains(".") && !s.contains(" ") {
            return "https://" + s
        }
        return s
    }

    func looksLikeUrl(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return false }

        let lower = s.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") { return true }
        if s.contains(".") && !s.contains(" ") { return true }
        return false
    }

    func normalizedInputForScan() -> String {
        switch selectedType {
        case .phone:
            return phoneDigits.trimmingCharacters(in: .whitespacesAndNewlines)

        case .bank:
            if bankMode == .byAccount {
                // Keep leading zeros, only strip non-digits
                return inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    .filter { $0.isNumber }
            }

            return fullNameInput
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .joined(separator: " ")

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

    // MARK: - Phone Scan

    func runPhoneScan() async -> ScanResult? {
        let cleaned = phoneDigits.filter { "0123456789+".contains($0) }
        guard !cleaned.isEmpty else {
            errorMessage = "กรุณากรอกเบอร์โทรศัพท์"
            return nil
        }

        let numericOnly = cleaned.filter { $0.isNumber }
        if numericOnly.count < 9 {
            errorMessage = "เบอร์โทรสั้นเกินไป"
            return nil
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let dbResult = await riskService.scanDatabaseOnly(type: .phone, input: cleaned)

        var heuristic: [String] = ["Heuristic: ตรวจรูปแบบหมายเลขโทรศัพท์"]
        heuristic.append("• จำนวนตัวเลข: \(numericOnly.count)")
        if Set(numericOnly).count <= 2 { heuristic.append("• เลขซ้ำ/แพทเทิร์นแปลก (น่าสงสัย)") }

        if let meta = phoneValidator.validateNumber(cleaned) {
            heuristic.append("• ประเภท: \(meta.numberType)")
            heuristic.append("• เครือข่าย: \(meta.carrier)")
            heuristic.append("• พื้นที่: \(meta.origin)")
            if meta.hasSuspiciousPattern { heuristic.append("• ลักษณะเข้าข่ายเบอร์สร้างขึ้น/เบอร์หลอก") }
            if meta.isVerifiedService { heuristic.append("• อยู่ใน whitelist/บริการที่เชื่อถือได้") }
        }

        let reasons: [String]
        if dbResult.reasons.contains(RiskService.noDataReason) {
            reasons = ([RiskService.noDataReason] + heuristic).uniquedPreservingOrder()
        } else {
            reasons = (dbResult.reasons + heuristic).uniquedPreservingOrder()
        }

        let result = ScanResult(type: .phone, input: cleaned, riskLevel: dbResult.riskLevel, reasons: reasons)
        historyStore.add(result)
        return result
    }

    // MARK: - Bank Scan

    func runBankScan() async -> ScanResult? {
        let input = normalizedInputForScan()
        guard !input.isEmpty else {
            errorMessage = "กรุณากรอกข้อมูล"
            return nil
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if bankMode == .byAccount {
                let reports = await bankRepository.fetchUserReports(accountNumber: input)
                let entry = try await bankRepository.fetchByAccountNumber(input)

                var heuristic: [String] = ["Heuristic: ตรวจรูปแบบเลขบัญชี"]
                heuristic.append("• ความยาว: \(input.count) หลัก")
                if input.count < 8 { heuristic.append("• ความยาวสั้นผิดปกติ") }
                if Set(input).count <= 2 { heuristic.append("• เลขซ้ำ/แพทเทิร์นแปลก (น่าสงสัย)") }

                if let e = entry {
                    var reasons: [String] = []
                    if let bank = e.bank_name, !bank.isEmpty { reasons.append("ธนาคาร: \(bank)") }
                    if let name = e.name, !name.isEmpty { reasons.append("ชื่อผู้รับ: \(name)") }
                    reasons.append(contentsOf: e.reasons ?? [])
                    reasons.append(contentsOf: reports)
                    reasons.append(contentsOf: heuristic)

                    var result = ScanResult(type: .bank, input: input, riskLevel: e.riskLevel, reasons: reasons.uniquedPreservingOrder())
                    result.bankName = e.bank_name
                    result.ownerName = e.name
                    historyStore.add(result)
                    return result
                }

                let reasons = ([RiskService.noDataReason] + reports + heuristic).uniquedPreservingOrder()
                let result = ScanResult(type: .bank, input: input, riskLevel: .low, reasons: reasons)
                historyStore.add(result)
                return result

            } else {
                let matches = try await bankRepository.fetchByOwnerName(input)

                var heuristic: [String] = ["Heuristic: ตรวจรูปแบบชื่อ"]
                heuristic.append("• จำนวนคำ: \(input.split(separator: " ").count)")
                if input.count < 6 { heuristic.append("• ชื่อสั้นผิดปกติ") }

                guard !matches.isEmpty else {
                    let reasons = ([RiskService.noDataReason] + heuristic).uniquedPreservingOrder()
                    let result = ScanResult(type: .bank, input: input, riskLevel: .low, reasons: reasons)
                    historyStore.add(result)
                    return result
                }

                let worst = matches.max(by: { $0.riskLevel < $1.riskLevel }) ?? matches[0]

                var reasons: [String] = ["พบชื่อใน bank_blacklist จำนวน \(matches.count) รายการ"]
                if let bank = worst.bank_name, !bank.isEmpty { reasons.append("ธนาคาร: \(bank)") }
                if let name = worst.name, !name.isEmpty { reasons.append("ชื่อผู้รับ: \(name)") }
                reasons.append(contentsOf: worst.reasons ?? [])
                reasons.append(contentsOf: heuristic)

                var result = ScanResult(type: .bank, input: input, riskLevel: worst.riskLevel, reasons: reasons.uniquedPreservingOrder())
                result.bankName = worst.bank_name
                result.ownerName = worst.name
                historyStore.add(result)
                return result
            }
        } catch {
            errorMessage = "เชื่อมต่อฐานข้อมูลธนาคารไม่สำเร็จ"
            return nil
        }
    }

    // MARK: - URL / QR / SMS / Text Scan

    func runScan() async -> ScanResult? {
        let input = normalizedInputForScan()
        guard !input.isEmpty else {
            errorMessage = "กรุณากรอกข้อมูล"
            return nil
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch selectedType {
        case .url, .qr:
            let analysis = await urlAnalyzer.analyzeWithDB(input)
            let noData = analysis.reasons.first == "ไม่มีข้อมูลในระบบ"

            let reasons: [String]
            if noData {
                let tail = analysis.reasons.filter { $0 != "ไม่มีข้อมูลในระบบ" }
                reasons = ([RiskService.noDataReason] + tail).uniquedPreservingOrder()
            } else {
                reasons = analysis.reasons.uniquedPreservingOrder()
            }

            let result = ScanResult(type: selectedType, input: analysis.normalizedUrl, riskLevel: analysis.level, reasons: reasons)
            historyStore.add(result)
            return result

        case .sms, .text:
            let sms = smsAnalyzer.scan(input)

            // Base reasons from SMS heuristic
            var mergedReasons = sms.reasons

            if let firstUrl = sms.urls.first {
                let urlAnalysis = await urlAnalyzer.analyzeWithDB(normalizeUrlInput(firstUrl))
                let worst = max(sms.riskLevel, urlAnalysis.level)

                mergedReasons.append("ลิงก์ที่พบ: \(urlAnalysis.normalizedUrl)")
                mergedReasons.append(contentsOf: urlAnalysis.reasons)

                let noData = urlAnalysis.reasons.first == "ไม่มีข้อมูลในระบบ"
                let reasons: [String]

                if noData {
                    let cleaned = mergedReasons.filter { $0 != "ไม่มีข้อมูลในระบบ" }
                    reasons = ([RiskService.noDataReason] + cleaned).uniquedPreservingOrder()
                } else {
                    reasons = mergedReasons.uniquedPreservingOrder()
                }

                let result = ScanResult(type: .sms, input: input, riskLevel: worst, reasons: reasons)
                historyStore.add(result)
                return result
            }

            // No URL inside SMS -> still return SMS heuristic, with NO DATA marker
            let reasons = ([RiskService.noDataReason] + mergedReasons).uniquedPreservingOrder()
            let result = ScanResult(type: .sms, input: input, riskLevel: sms.riskLevel, reasons: reasons)
            historyStore.add(result)
            return result

        default:
            let db = await riskService.scanDatabaseOnly(type: selectedType, input: input)
            historyStore.add(db)
            return db
        }
    }
}
