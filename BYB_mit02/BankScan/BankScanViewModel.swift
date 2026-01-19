//
//  BankScanViewModel.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//

import Foundation
import FirebaseFirestore

@MainActor
final class BankScanViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var accountNumberInput: String = ""   // ✅ ชัดว่าเป็นเลขบัญชี
    @Published var inputFullName: String = ""        // ✅ ช่องชื่อ-นามสกุล
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()

    // MARK: - Search Logic

    func scanBankAccount(mode: BankSearchMode) async -> ScanResult? {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            if mode == .byAccount {
                // ✅ การค้นหาด้วยเลขบัญชี (Document ID)
                let normalized = accountNumberInput.filter(\.isNumber)
                guard !normalized.isEmpty else {
                    errorMessage = "กรุณากรอกเลขบัญชีให้ถูกต้อง"
                    return nil
                }

                let docRef = db.collection("bank_blacklist").document(normalized)
                let snapshot = try await docRef.getDocument()

                if snapshot.exists, let data = snapshot.data() {
                    return makeScanResult(from: data, input: normalized)
                }
            } else {
                // ✅ การค้นหาด้วยชื่อ-นามสกุล (ช่องกรอกเดียว)
                let fullName = inputFullName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")

                guard !fullName.isEmpty else {
                    errorMessage = "กรุณากรอกชื่อและนามสกุล"
                    return nil
                }

                let query = db.collection("bank_blacklist").whereField("name", isEqualTo: fullName)
                let snapshot = try await query.getDocuments()

                if let document = snapshot.documents.first {
                    return makeScanResult(from: document.data(), input: fullName)
                }
            }

            // กรณีไม่พบข้อมูลใน Blacklist ให้แสดงผลเป็นปลอดภัย
            let displayInput = (mode == .byAccount) ? accountNumberInput : inputFullName
            return ScanResult(
                type: .bank,
                input: displayInput,
                riskLevel: .low,
                reasons: [RiskService.noDataReason]
            )

        } catch {
            errorMessage = "เกิดข้อผิดพลาดในการเชื่อมต่อ: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Helper Methods

    /// แปลงข้อมูลจาก Firestore เป็น ScanResult เพื่อนำไปแสดงผล
    private func makeScanResult(from data: [String: Any], input: String) -> ScanResult {
        let rawLevel = data["level"] as? String ?? "low"
        let riskLevel: RiskLevel =
            (rawLevel.lowercased() == "high") ? .high :
            (rawLevel.lowercased() == "medium") ? .medium : .low

        let reasons = data["reasons"] as? [String] ?? ["พบรายการต้องสงสัยในฐานข้อมูล"]

        var result = ScanResult(
            type: .bank,
            input: input,
            riskLevel: riskLevel,
            reasons: reasons
        )

        result.ownerName = data["name"] as? String
        result.bankName = data["bank_name"] as? String

        return result
    }

    /// ใช้สำหรับกรอกข้อมูลทดสอบเพื่อยืนยันการเชื่อมต่อฐานข้อมูล
    func fillSampleData() {
        self.inputFullName = "กาญจนา ทรัพย์แสน"
    }

    func clearAllInputs() {
        accountNumberInput = ""
        inputFullName = ""
        errorMessage = nil
    }
}
