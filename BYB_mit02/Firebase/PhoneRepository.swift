//
//  FirestorePhoneRepository.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 14/1/2569 BE.
//



//
//  PhoneRepository.swift
//  BYB_mit02
//

import FirebaseFirestore


final class PhoneRepository {
    private let db = Firestore.firestore()

    func fetchBlacklist(phoneNumber: String) async -> ScanResult? {
        let docRef = db.collection("phone_blacklist").document(phoneNumber)

        do {
            let document = try await docRef.getDocument()
            guard document.exists, let data = document.data() else { return nil }

            let reasons = data["reasons"] as? [String] ?? []
            let levelStr = data["level"] as? String ?? "low"

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
                riskLevel: level,
                reasons: reasons
            )
        } catch {
            print("❌ Firestore phone_blacklist error:", error.localizedDescription)
            return nil
        }
    }
}

