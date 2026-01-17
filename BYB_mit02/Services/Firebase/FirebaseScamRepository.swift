//
//  FirebaseScamRepository.swift
//  BYB_mit02
//

import Foundation
import FirebaseFirestore

final class FirebaseScamRepository: ScamRepository {

    private let db = Firestore.firestore()

    func findMatches(type: ScanType, input: String) async -> [ScamEntry] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case .phone:
            return await findPhoneMatches(phone: trimmed)

        case .bank:
            return await findBankMatches(account: trimmed)

        case .url, .qr:
            return await findUrlMatches(url: trimmed)

        case .sms, .text, .faceScan, .report:
            return []
        }
    }

    // MARK: - Phone

    private func findPhoneMatches(phone: String) async -> [ScamEntry] {
        // ✅ normalize เบอร์ให้เป็นเลขล้วน เพราะ docID ใน blacklist เป็นเลข
        let q = phone.filter { $0.isNumber }
        guard !q.isEmpty else { return [] }

        // 1) ✅ ดึงจาก phone_blacklist โดยใช้ docID
        do {
            let doc = try await db.collection("phone_blacklist").document(q).getDocument()
            if doc.exists, let data = doc.data() {
                let reasons = data["reasons"] as? [String] ?? []
                let level = (data["level"] as? String) ?? "high"

                let label = "phone_blacklist (\(level))"
                let note = reasons.isEmpty ? "พบใน blacklist" : reasons.joined(separator: " / ")

                return [
                    ScamEntry(kind: .phone, value: q, label: label, note: note)
                ]
            }
        } catch {
            print("❌ Firestore phone_blacklist error:", error.localizedDescription)
        }

        // 2) (เสริม) ตรวจจากรายงานผู้ใช้ phone_report (ถ้ามี)
        do {
            let snap = try await db
                .collection("phone_report")
                .whereField("phoneNumber", isEqualTo: phone) // ใน ReportScamView คุณส่ง field นี้
                .limit(to: 10)
                .getDocuments()

            if !snap.documents.isEmpty {
                return snap.documents.map { d in
                    let data = d.data()
                    let reason = (data["reason"] as? String) ?? "รายงานผู้ใช้"
                    let note = (data["note"] as? String) ?? ""
                    return ScamEntry(kind: .phone, value: phone, label: "รายงานผู้ใช้: \(reason)", note: note)
                }
            }
        } catch {
            print("❌ Firestore phone_report error:", error.localizedDescription)
        }

        return []
    }

    // MARK: - Bank

    private func findBankMatches(account: String) async -> [ScamEntry] {
        // ✅ normalize เลขบัญชีเป็นเลขล้วน (ถ้า docID เก็บเป็นเลขล้วน)
        let q = account.filter { $0.isNumber }
        guard !q.isEmpty else { return [] }

        // 1) ✅ blacklist โดย docID
        do {
            let doc = try await db.collection("bank_blacklist").document(q).getDocument()
            if doc.exists, let data = doc.data() {
                let reasons = data["reasons"] as? [String] ?? []
                let level = (data["level"] as? String) ?? "high"

                let label = "bank_blacklist (\(level))"
                let note = reasons.isEmpty ? "พบใน blacklist" : reasons.joined(separator: " / ")

                return [
                    ScamEntry(kind: .bankAccount, value: q, label: label, note: note)
                ]
            }
        } catch {
            print("❌ Firestore bank_blacklist error:", error.localizedDescription)
        }

        // 2) (เสริม) รายงานผู้ใช้ bank_report
        do {
            let snap = try await db
                .collection("bank_report")
                .whereField("accountNumber", isEqualTo: account) // ใน ReportScamView คุณส่ง field นี้
                .limit(to: 10)
                .getDocuments()

            if !snap.documents.isEmpty {
                return snap.documents.map { d in
                    let data = d.data()
                    let note = (data["note"] as? String) ?? ""
                    let bankName = (data["bankName"] as? String) ?? ""
                    return ScamEntry(kind: .bankAccount, value: account, label: "รายงานผู้ใช้ \(bankName)", note: note)
                }
            }
        } catch {
            print("❌ Firestore bank_report error:", error.localizedDescription)
        }

        return []
    }

    // MARK: - URL

    private func findUrlMatches(url: String) async -> [ScamEntry] {
        let q = url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        // ตอนนี้คุณมี link_report (เป็นรายงานผู้ใช้)
        do {
            let snap = try await db
                .collection("link_report")
                .whereField("link", isEqualTo: url) // ใน ReportScamView คุณส่ง field นี้
                .limit(to: 10)
                .getDocuments()

            if !snap.documents.isEmpty {
                return snap.documents.map { d in
                    let data = d.data()
                    let note = (data["note"] as? String) ?? ""
                    return ScamEntry(kind: .url, value: url, label: "รายงานผู้ใช้: link_report", note: note)
                }
            }
        } catch {
            print("❌ Firestore link_report error:", error.localizedDescription)
        }

        return []
    }
}
