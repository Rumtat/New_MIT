//
//  BankFirestoreService.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 17/1/2569 BE.
//


//
//  BankFirestoreService.swift
//  BYB_mit02
//

import Foundation
import FirebaseFirestore

final class BankFirestoreService {
    private let db = Firestore.firestore()

    /// Fetch by Account (docID = account digits, may include leading zeros)
    func fetchBlacklistByAccount(_ accountDigits: String) async throws -> BankBlacklistEntry? {
        let q = accountDigits.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nil }

        let doc = try await db.collection("bank_blacklist").document(q).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }

        return BankBlacklistEntry(
            id: doc.documentID,
            bank_name: data["bank_name"] as? String,
            level: data["level"] as? String,
            name: data["name"] as? String,
            reasons: data["reasons"] as? [String]
        )
    }

    /// Fetch by Name (exact match)
    func fetchBlacklistByName(_ fullName: String) async throws -> [BankBlacklistEntry] {
        let q = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        let snap = try await db
            .collection("bank_blacklist")
            .whereField("name", isEqualTo: q)
            .limit(to: 20)
            .getDocuments()

        return snap.documents.map { d in
            let data = d.data()
            return BankBlacklistEntry(
                id: d.documentID,
                bank_name: data["bank_name"] as? String,
                level: data["level"] as? String,
                name: data["name"] as? String,
                reasons: data["reasons"] as? [String]
            )
        }
    }

    /// Extra: look into bank_report for user reports (optional)
    func fetchReportsByAccount(_ accountRaw: String) async -> [String] {
        do {
            let snap = try await db
                .collection("bank_report")
                .whereField("accountNumber", isEqualTo: accountRaw)
                .limit(to: 10)
                .getDocuments()

            if snap.documents.isEmpty { return [] }

            return snap.documents.compactMap { d in
                let data = d.data()
                let bankName = (data["bankName"] as? String) ?? ""
                let note = (data["note"] as? String) ?? ""
                let reason = (data["reason"] as? String) ?? ""
                let parts = [bankName, reason, note].filter { !$0.isEmpty }
                return parts.isEmpty ? "รายงานผู้ใช้ (bank_report)" : "รายงานผู้ใช้: " + parts.joined(separator: " / ")
            }
        } catch {
            return []
        }
    }
}
