//
//  FirebaseScamRepository.swift
//  BYB_mit02
//
//
//  FirebaseScamRepository.swift
//  BYB_mit02
//

import Foundation
import FirebaseFirestore

final class FirebaseScamRepository: ScamRepository {

    private let db = Firestore.firestore()

    func findEntries(type: ScanType, input: String) async -> [ScamEntry] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case .phone:
            return await findPhoneEntries(phoneNumber: trimmed)

        case .bank:
            return await findBankEntries(accountNumber: trimmed)

        case .url, .qr:
            return await findUrlEntries(urlString: trimmed)

        case .sms, .text, .faceScan, .report:
            return []
        }
    }

    // MARK: - Phone

    private func findPhoneEntries(phoneNumber: String) async -> [ScamEntry] {
        let q = phoneNumber.filter { $0.isNumber }
        guard !q.isEmpty else { return [] }

        var results: [ScamEntry] = []

        // 1) blacklist by docID
        do {
            let doc = try await db.collection("phone_blacklist").document(q).getDocument()
            if doc.exists, let data = doc.data() {
                let reasons = data["reasons"] as? [String] ?? []
                let label = (data["label"] as? String) ?? "phone_blacklist"
                let level = (data["level"] as? String) ?? "high"

                let note = reasons.isEmpty ? "พบใน blacklist" : reasons.joined(separator: " / ")

                results.append(
                    ScamEntry(
                        kind: .phone,
                        value: q,
                        label: "\(label) (\(level))",
                        note: note
                    )
                )
            }
        } catch {
            print("❌ Firestore phone_blacklist error:", error.localizedDescription)
        }

        // 2) user report
        do {
            let snap = try await db
                .collection("phone_report")
                .whereField("phoneNumber", isEqualTo: phoneNumber)
                .limit(to: 10)
                .getDocuments()

            if !snap.documents.isEmpty {
                let mapped = snap.documents.map { d -> ScamEntry in
                    let data = d.data()
                    let reason = (data["reason"] as? String) ?? "รายงานผู้ใช้"
                    let note = (data["note"] as? String) ?? ""
                    return ScamEntry(kind: .phone, value: phoneNumber, label: "รายงานผู้ใช้: \(reason)", note: note)
                }
                results.append(contentsOf: mapped)
            }
        } catch {
            print("❌ Firestore phone_report error:", error.localizedDescription)
        }

        return results
    }

    // MARK: - Bank

    private func findBankEntries(accountNumber: String) async -> [ScamEntry] {
        let q = accountNumber.filter { $0.isNumber }
        guard !q.isEmpty else { return [] }

        var results: [ScamEntry] = []

        // 1) blacklist by docID
        do {
            let doc = try await db.collection("bank_blacklist").document(q).getDocument()
            if doc.exists, let data = doc.data() {
                let reasons = data["reasons"] as? [String] ?? []
                let label = (data["label"] as? String) ?? "bank_blacklist"
                let level = (data["level"] as? String) ?? "high"
                let bankName = (data["bank_name"] as? String) ?? ""
                let name = (data["name"] as? String) ?? ""

                var pieces: [String] = []
                if !bankName.isEmpty { pieces.append("ธนาคาร: \(bankName)") }
                if !name.isEmpty { pieces.append("ชื่อ: \(name)") }
                if !reasons.isEmpty { pieces.append(contentsOf: reasons) }

                let note = pieces.isEmpty ? "พบใน blacklist" : pieces.joined(separator: " / ")

                results.append(
                    ScamEntry(
                        kind: .bankAccount,
                        value: q,
                        label: "\(label) (\(level))",
                        note: note
                    )
                )
            }
        } catch {
            print("❌ Firestore bank_blacklist error:", error.localizedDescription)
        }

        // 2) user report
        do {
            let snap = try await db
                .collection("bank_report")
                .whereField("accountNumber", isEqualTo: accountNumber)
                .limit(to: 10)
                .getDocuments()

            if !snap.documents.isEmpty {
                let mapped = snap.documents.map { d -> ScamEntry in
                    let data = d.data()
                    let note = (data["note"] as? String) ?? ""
                    let bankName = (data["bankName"] as? String) ?? ""
                    return ScamEntry(kind: .bankAccount, value: accountNumber, label: "รายงานผู้ใช้ \(bankName)", note: note)
                }
                results.append(contentsOf: mapped)
            }
        } catch {
            print("❌ Firestore bank_report error:", error.localizedDescription)
        }

        return results
    }

    // MARK: - URL

    private func findUrlEntries(urlString: String) async -> [ScamEntry] {
        let q = urlString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        var results: [ScamEntry] = []

        // link_report (user reports)
        do {
            let snap = try await db
                .collection("link_report")
                .whereField("link", isEqualTo: urlString)
                .limit(to: 10)
                .getDocuments()

            if !snap.documents.isEmpty {
                let mapped = snap.documents.map { d -> ScamEntry in
                    let data = d.data()
                    let note = (data["note"] as? String) ?? ""
                    return ScamEntry(kind: .url, value: urlString, label: "รายงานผู้ใช้: link_report", note: note)
                }
                results.append(contentsOf: mapped)
            }
        } catch {
            print("❌ Firestore link_report error:", error.localizedDescription)
        }

        return results
    }
}

protocol ScamRepository {
    func findEntries(type: ScanType, input: String) async -> [ScamEntry]
}
