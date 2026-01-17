//
//  BankScamRepositoryProtocol.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//
/*
import Foundation
import FirebaseFirestore

protocol BankScamRepositoryProtocol {
    func fetchBlacklistByAccount(_ account: String) async throws -> BankBlacklistEntry?
    func fetchBlacklistByName(_ name: String) async throws -> BankBlacklistEntry?
}

final class BankScamRepository: BankScamRepositoryProtocol {
    private let db = Firestore.firestore()

    // ค้นหาด้วยเลขบัญชี (หาจากชื่อ Document ID)
    func fetchBlacklistByAccount(_ account: String) async throws -> BankBlacklistEntry? {
        let normalized = account.filter(\.isNumber)
        let ref = db.collection("bank_blacklist").document(normalized)
        let snap = try await ref.getDocument()
        guard snap.exists else { return nil }
        var entry = try snap.data(as: BankBlacklistEntry.self)
        entry.id = snap.documentID
        return entry
    }

    // ✅ ค้นหาจากฟิลด์ "name" ภายในเอกสาร
    func fetchBlacklistByName(_ name: String) async throws -> BankBlacklistEntry? {
        let snapshot = try await db.collection("bank_blacklist")
            .whereField("name", isEqualTo: name) // ค้นหาเจาะจงไปที่ฟิลด์ name
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        var entry = try doc.data(as: BankBlacklistEntry.self)
        entry.id = doc.documentID
        return entry
    }
}
*/

