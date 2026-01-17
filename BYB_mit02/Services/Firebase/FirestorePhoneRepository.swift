//
//  FirestorePhoneRepository.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 14/1/2569 BE.
//


import FirebaseFirestore

final class FirestorePhoneRepository {
    private let db = Firestore.firestore()

    func checkBlacklist(phoneNumber: String) async -> ScanResult? {
        // ✅ ดึงข้อมูลจากคอลเลกชัน phone_blacklist โดยใช้เบอร์โทรเป็น ID (Document ID)
        let docRef = db.collection("phone_blacklist").document(phoneNumber)
        
        do {
            let document = try await docRef.getDocument()
            
            if document.exists, let data = document.data() {
                // ✅ ดึงข้อมูลและแปลงค่าตามโครงสร้างใน Firebase Console (รูปที่ 43)
                let reasons = data["reasons"] as? [String] ?? []
                let levelStr = data["level"] as? String ?? "low"
                
                // แปลง String เป็น RiskLevel Enum
                let level: RiskLevel = {
                    switch levelStr {
                    case "high": return .high
                    case "medium": return .medium
                    default: return .low
                    }
                }()
                
                return ScanResult(
                    type: .phone,
                    input: phoneNumber,
                    level: level,
                    reasons: reasons
                )
            }
        } catch {
            print("❌ Firestore Error: \(error.localizedDescription)")
        }
        return nil
    }
}


