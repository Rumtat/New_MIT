//
//  SmsRiskAnalyzer.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 17/1/2569 BE.
//


//
//  SmsRiskAnalyzer.swift
//  BYB_mit02
//
//  Heuristic checks for SMS / message text.
//

import Foundation

struct SmsRiskAnalyzer {
    struct Analysis {
        let level: RiskLevel
        let reasons: [String]
        let extractedUrls: [String]
    }

    func analyze(_ text: String) -> Analysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .init(level: .medium, reasons: ["กรุณาวางข้อความ"], extractedUrls: [])
        }

        let urls = extractUrls(from: trimmed)

        var score = 0
        var reasons: [String] = []

        let patterns = [
            ("ด่วน", 1), ("ระงับ", 1), ("ยืนยัน", 1), ("ปรับปรุง", 1),
            ("ของรางวัล", 2), ("พัสดุ", 1), ("ชำระ", 1), ("คืนเงิน", 1),
            ("OTP", 2), ("รหัส", 1), ("บัญชี", 1), ("ธนาคาร", 1)
        ]

        for (k, w) in patterns {
            if trimmed.localizedCaseInsensitiveContains(k) {
                score += w
            }
        }

        if score >= 3 {
            reasons.append("ข้อความมีคำ/รูปแบบที่พบบ่อยในมิจฉาชีพ")
        }

        if !urls.isEmpty {
            score += 2
            reasons.append("พบลิงก์ภายในข้อความ")
        }

        let level: RiskLevel
        if score >= 5 {
            level = .high
        } else if score >= 2 {
            level = .medium
        } else {
            level = .low
        }

        if reasons.isEmpty {
            reasons = ["ไม่พบรูปแบบเสี่ยงเด่นชัด"]
        }

        return .init(level: level, reasons: reasons, extractedUrls: urls)
    }

    private func extractUrls(from text: String) -> [String] {
        let pattern = "(?i)\\b((?:https?://)?(?:[a-z0-9-]+\\.)+[a-z]{2,}(?:/[^\\s]*)?)\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap { m in
            guard let r = Range(m.range(at: 1), in: text) else { return nil }
            return String(text[r])
        }
        .prefix(5)
        .map { $0 }
    }
}
