//
//  SmsScanAnalyzer.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 17/1/2569 BE.
//

import Foundation

// MARK: - Analyzer

final class SmsScanAnalyzer {

    func scan(_ text: String) -> SmsScanResult {
        let inputText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !inputText.isEmpty else {
            return SmsScanResult(
                riskLevel: .low,
                reasons: ["Heuristic: ข้อความว่าง"],
                urls: [],
                phoneNumbers: [],
                bankAccounts: []
            )
        }

        var score = 0
        var reasons: [String] = ["Heuristic: วิเคราะห์ข้อความ (SMS/Text)"]

        let lowercasedText = inputText.lowercased()

        // MARK: - Urgency / Pressure
        let urgencyWords = [
            "ด่วน", "ภายใน", "ทันที", "เร่งด่วน",
            "จะถูกระงับ", "บัญชีถูกระงับ",
            "ภายใน24", "ภายใน 24", "วันนี้เท่านั้น"
        ]

        if urgencyWords.contains(where: {
            lowercasedText.contains($0.replacingOccurrences(of: " ", with: ""))
            || lowercasedText.contains($0)
        }) {
            score += 15
            reasons.append("• พบคำกดดัน/เร่งเวลา → เสี่ยง")
        }

        // MARK: - Sensitive Info Request
        let sensitiveWords = [
            "otp", "รหัส", "รหัสผ่าน", "password",
            "pin", "เลขบัตร", "cvv", "โค้ด",
            "ยืนยันตัวตน", "ยืนยันบัญชี"
        ]

        if sensitiveWords.contains(where: { lowercasedText.contains($0) }) {
            score += 25
            reasons.append("• พบการขอข้อมูลสำคัญ (OTP/รหัส/ยืนยันตัวตน) → เสี่ยงสูง")
        }

        // MARK: - Impersonation
        let impersonationWords = [
            "ธนาคาร", "ตำรวจ", "สรรพากร", "ขนส่ง",
            "ไปรษณีย์", "กรม", "ศาล",
            "kbank", "scb", "bbl", "ktb", "bay", "gsb", "promptpay"
        ]

        if impersonationWords.contains(where: { lowercasedText.contains($0) }) {
            score += 10
            reasons.append("• มีคำแอบอ้างหน่วยงาน/ธนาคาร → ระวัง")
        }

        // MARK: - Money Lure
        let lureWords = [
            "เงินคืน", "refund", "รับเงิน",
            "โบนัส", "reward", "prize",
            "ของรางวัล", "คูปอง", "เครดิตฟรี"
        ]

        if lureWords.contains(where: { lowercasedText.contains($0) }) {
            score += 10
            reasons.append("• พบการล่อให้กด/รับเงิน/รางวัล → ระวัง")
        }

        // MARK: - Extraction
        let urls = extractURLs(from: inputText)
        if !urls.isEmpty {
            score += 10
            reasons.append("• พบลิงก์ในข้อความ \(urls.count) ลิงก์")
        }

        let phoneNumbers = extractPhoneNumbers(from: inputText)
        if !phoneNumbers.isEmpty {
            reasons.append("• พบเบอร์โทรในข้อความ \(phoneNumbers.count) รายการ")
        }

        let bankAccounts = extractBankAccounts(from: inputText)
        if !bankAccounts.isEmpty {
            reasons.append("• พบเลขบัญชี/เลขอ้างอิงที่เป็นตัวเลขยาว \(bankAccounts.count) รายการ")
        }

        // MARK: - Combined Risk
        if !urls.isEmpty && sensitiveWords.contains(where: { lowercasedText.contains($0) }) {
            score += 20
            reasons.append("• พบลิงก์ + ขอข้อมูลสำคัญ พร้อมกัน → เสี่ยงสูงมาก")
        }

        // MARK: - Final Risk Level
        let riskLevel: RiskLevel
        if score >= 55 {
            riskLevel = .high
        } else if score >= 25 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }

        reasons.append("• คะแนนความเสี่ยง (Heuristic): \(score)")

        return SmsScanResult(
            riskLevel: riskLevel,
            reasons: reasons,
            urls: urls,
            phoneNumbers: phoneNumbers,
            bankAccounts: bankAccounts
        )
    }

    // MARK: - Helpers

    private func extractURLs(from text: String) -> [String] {
        var results: [String] = []

        let pattern1 = #"https?:\/\/[^\s]+"#
        if let regex = try? NSRegularExpression(pattern: pattern1, options: .caseInsensitive) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            for m in regex.matches(in: text, range: range) {
                if let r = Range(m.range, in: text) {
                    results.append(String(text[r]))
                }
            }
        }

        let pattern2 = #"(?:^|\s)([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,}(?:\/[^\s]*)?"#
        if let regex = try? NSRegularExpression(pattern: pattern2, options: .caseInsensitive) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            for m in regex.matches(in: text, range: range) {
                if let r = Range(m.range, in: text) {
                    let token = text[r].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !token.lowercased().hasPrefix("http") {
                        results.append(token)
                    }
                }
            }
        }

        return Array(Set(results)).sorted()
    }

    private func extractPhoneNumbers(from text: String) -> [String] {
        let digits = text.map { $0.isNumber ? $0 : " " }
        let chunks = String(digits).split(separator: " ").map(String.init)
        let candidates = chunks.filter { $0.count >= 9 && $0.count <= 15 }
        return Array(Set(candidates)).sorted()
    }

    private func extractBankAccounts(from text: String) -> [String] {
        let digits = text.map { $0.isNumber ? $0 : " " }
        let chunks = String(digits).split(separator: " ").map(String.init)
        let candidates = chunks.filter { $0.count >= 10 && $0.count <= 15 }
        return Array(Set(candidates)).sorted()
    }
}
