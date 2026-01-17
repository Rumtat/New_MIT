//
//  UrlRiskAnalyzer.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 17/1/2569 BE.
//


//
//  UrlRiskAnalyzer.swift
//  BYB_mit02
//
//  Lightweight heuristic URL risk checks (offline) to complement database matching.
//

import Foundation

struct UrlRiskAnalyzer {
    struct Analysis {
        let normalizedUrl: String
        let level: RiskLevel
        let reasons: [String]
    }

    func analyze(_ raw: String) -> Analysis {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .init(normalizedUrl: "", level: .medium, reasons: ["กรุณาระบุลิงก์"])
        }

        // Add scheme if missing
        let withScheme: String
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            withScheme = trimmed
        } else {
            withScheme = "https://" + trimmed
        }

        guard let components = URLComponents(string: withScheme),
              let host = components.host, !host.isEmpty
        else {
            return .init(
                normalizedUrl: trimmed,
                level: .medium,
                reasons: ["ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์"]
            )
        }

        var reasons: [String] = []
        var score = 0

        let scheme = (components.scheme ?? "").lowercased()
        if scheme != "https" {
            score += 1
            reasons.append("ลิงก์ไม่ได้ใช้ HTTPS")
        }

        let lower = withScheme.lowercased()
        if lower.contains("@") {
            score += 2
            reasons.append("ลิงก์มี '@' (มักใช้หลอกให้เข้าใจผิด)")
        }
        if lower.contains("%00") || lower.contains("%2f%2f") {
            score += 1
            reasons.append("ลิงก์มีรูปแบบ encoding ที่พบบ่อยในลิงก์อันตราย")
        }

        // Host heuristics
        if isIpAddress(host) {
            score += 2
            reasons.append("ใช้ IP แทนโดเมน (ความเสี่ยงสูง)")
        }
        let parts = host.split(separator: ".")
        if parts.count >= 4 {
            score += 1
            reasons.append("โดเมนมี subdomain หลายชั้น")
        }
        let hyphenCount = host.filter { $0 == "-" }.count
        if hyphenCount >= 3 {
            score += 1
            reasons.append("โดเมนมีขีด '-' จำนวนมาก")
        }

        // Common phishing keywords
        let keywords = ["login", "verify", "update", "secure", "account", "wallet", "bank", "otp", "payment", "refund"]
        if keywords.contains(where: { lower.contains($0) }) {
            score += 1
            reasons.append("พบคำที่มักใช้ในลิงก์ฟิชชิ่ง")
        }

        let level: RiskLevel
        if score >= 4 {
            level = .high
        } else if score >= 2 {
            level = .medium
        } else {
            level = .low
        }

        if reasons.isEmpty {
            reasons = ["โครงสร้างลิงก์ปกติ"]
        }

        let normalized = components.string ?? withScheme
        return .init(normalizedUrl: normalized, level: level, reasons: reasons)
    }

    private func isIpAddress(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return false }
        for p in parts {
            guard let n = Int(p), n >= 0 && n <= 255 else { return false }
        }
        return true
    }
}
