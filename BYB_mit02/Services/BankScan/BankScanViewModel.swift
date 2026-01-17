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
    @Published var inputText: String = ""       // สำหรับเลขบัญชี
    @Published var inputFullName: String = ""    // ✅ สำหรับชื่อ-นามสกุลช่องเดียว
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()

    // MARK: - Search Logic
    
    func scanAccount(mode: BankSearchMode) async -> ScanResult? {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            if mode == .byAccount {
                // ✅ การค้นหาด้วยเลขบัญชี (Document ID)
                let normalized = inputText.filter(\.isNumber)
                guard !normalized.isEmpty else {
                    errorMessage = "กรุณากรอกเลขบัญชีให้ถูกต้อง"
                    return nil
                }
                
                let docRef = db.collection("bank_blacklist").document(normalized)
                let snapshot = try await docRef.getDocument()
                
                if snapshot.exists, let data = snapshot.data() {
                    return parseFirestoreData(data, input: normalized)
                }
            } else {
                // ✅ การค้นหาด้วยชื่อ-นามสกุล (ช่องกรอกเดียว)
                // ป้องกัน Human Error: จัดการช่องว่างให้เหลือ 1 ช่องเสมอเพื่อให้ตรงกับ Firestore
                let fullName = inputFullName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                
                guard !fullName.isEmpty else {
                    errorMessage = "กรุณากรอกชื่อและนามสกุล"
                    return nil
                }

                // ค้นหาฟิลด์ "name" ใน Firestore
                let query = db.collection("bank_blacklist").whereField("name", isEqualTo: fullName)
                let snapshot = try await query.getDocuments()
                
                if let document = snapshot.documents.first {
                    return parseFirestoreData(document.data(), input: fullName)
                }
            }
            
            // กรณีไม่พบข้อมูลใน Blacklist ให้แสดงผลเป็นปลอดภัย
            let displayInput = mode == .byAccount ? inputText : inputFullName
            return ScanResult(
                type: .bank,
                input: displayInput,
                level: .low,
                reasons: ["ไม่พบข้อมูลในฐานข้อมูลเฝ้าระวัง ณ ขณะนี้"]
            )
            
        } catch {
            errorMessage = "เกิดข้อผิดพลาดในการเชื่อมต่อ: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Helper Methods

    /// แปลงข้อมูลจาก Firestore เป็น ScanResult เพื่อนำไปแสดงผล
    private func parseFirestoreData(_ data: [String: Any], input: String) -> ScanResult {
        // ดึงสถานะระดับความเสี่ยง
        let rawLevel = data["level"] as? String ?? "low"
        let riskLevel: RiskLevel = (rawLevel.lowercased() == "high") ? .high : (rawLevel.lowercased() == "medium" ? .medium : .low)
        
        // รายการเหตุผล
        let reasons = data["reasons"] as? [String] ?? ["พบรายการต้องสงสัยในฐานข้อมูล"]
        
        // สร้าง Object ตาม ScanResult init
        var result = ScanResult(
            type: .bank,
            input: input,
            level: riskLevel,
            reasons: reasons
        )
        
        // กำหนดข้อมูลเพิ่มเติมที่ได้จาก Firebase
        result.ownerName = data["name"] as? String
        result.bankName = data["bank_name"] as? String
        
        return result
    }
    
    /// ใช้สำหรับกรอกข้อมูลทดสอบเพื่อยืนยันการเชื่อมต่อฐานข้อมูล
    func fillTestData() {
        self.inputFullName = "กาญจนา ทรัพย์แสน" //
    }
    
    func clearAllInputs() {
        inputText = ""
        inputFullName = ""
        errorMessage = nil
    }
}
