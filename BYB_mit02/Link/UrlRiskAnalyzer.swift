//
//  UrlRiskAnalyzer.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 17/1/2569 BE.
//


import Foundation

struct UrlAnalysisResult {
    let normalizedUrl: String
    let level: RiskLevel
    let reasons: [String]
}

final class UrlRiskAnalyzer {

    func analyze(_ raw: String) -> UrlAnalysisResult {
        let normalized = normalize(raw)

        guard let url = URL(string: normalized),
              let host = url.host?.lowercased()
        else {
            return UrlAnalysisResult(
                normalizedUrl: normalized,
                level: .high,
                reasons: [
                    "Heuristic: รูปแบบลิงก์ไม่ถูกต้อง",
                    "• ไม่สามารถแยก host จาก URL ได้"
                ]
            )
        }

        var score = 0
        var reasons: [String] = ["Heuristic: วิเคราะห์รูปแบบลิงก์"]

        let scheme = (url.scheme ?? "").lowercased()
        if scheme == "http" {
            score += 25
            reasons.append("• ใช้ HTTP (ไม่เข้ารหัส) → เสี่ยง")
        } else if scheme == "https" {
            reasons.append("• ใช้ HTTPS")
        } else {
            score += 10
            reasons.append("• scheme แปลก/ไม่ระบุ (\"\(scheme)\")")
        }

        let full = normalized.lowercased()

        // @ in URL (userinfo trick)
        if full.contains("@") {
            score += 35
            reasons.append("• พบ '@' ในลิงก์ (อาจหลอกให้เข้าใจผิด) → เสี่ยงสูง")
        }

        // IP address
        if isIPv4(host) {
            score += 30
            reasons.append("• ใช้ IP แทนโดเมน (\(host)) → เสี่ยง")
        }

        // Punycode
        if host.contains("xn--") {
            score += 25
            reasons.append("• โดเมนเป็น Punycode (xn--) อาจเป็นการเลียนแบบชื่อ → เสี่ยง")
        }

        // Suspicious port
        if let port = url.port, port != 80 && port != 443 {
            score += 15
            reasons.append("• ใช้พอร์ตแปลก :\(port) → เสี่ยง")
        }

        // Too many subdomains / long host
        let dotCount = host.filter { $0 == "." }.count
        if dotCount >= 3 {
            score += 10
            reasons.append("• มี subdomain หลายชั้น (\(dotCount+1) ส่วน) → เสี่ยง")
        }
        if host.count >= 35 {
            score += 10
            reasons.append("• ชื่อโดเมนยาวผิดปกติ (\(host.count) ตัว) → เสี่ยง")
        }

        // Hyphen abuse
        let hyphenCount = host.filter { $0 == "-" }.count
        if hyphenCount >= 4 {
            score += 10
            reasons.append("• มีเครื่องหมาย '-' จำนวนมาก → เสี่ยง")
        }

        // Short links (common)
        let shortDomains: Set<String> = [
            "bit.ly","t.co","tinyurl.com","goo.gl","rb.gy","is.gd","cutt.ly","ow.ly","rebrand.ly","buff.ly"
        ]
        if shortDomains.contains(host) {
            score += 25
            reasons.append("• เป็นลิงก์ย่อ (\(host)) → เสี่ยง (ควรขยายก่อนเปิด)")
        }

        // Phishing keywords in path/query
        let tokens = (url.path + " " + (url.query ?? "")).lowercased()
        let phishingKeywords = [
            "login","signin","verify","verification","update","secure","confirm","account","wallet",
            "reset","password","otp","payment","refund","claim","bonus","reward","prize"
        ]
        var hit = 0
        for k in phishingKeywords where tokens.contains(k) {
            hit += 1
        }
        if hit >= 2 {
            score += 15
            reasons.append("• พบคำที่มักใช้ในฟิชชิ่งหลายคำ (\(hit) คำ) → เสี่ยง")
        } else if hit == 1 {
            score += 8
            reasons.append("• พบคำที่มักใช้ในฟิชชิ่ง (\(phishingKeywords.first(where: { tokens.contains($0) }) ?? "-")) → ระวัง")
        }

        // Query parameter abuse
        if let q = url.query, q.count >= 80 {
            score += 10
            reasons.append("• query ยาวมาก (อาจมีการซ่อนข้อมูล) → เสี่ยง")
        }

        // Simple typosquatting-ish: digits replacing letters
        if host.contains("0") || host.contains("1") {
            score += 6
            reasons.append("• โดเมนมีตัวเลขปน (อาจเลียนแบบชื่อ) → ระวัง")
        }

        // Map score -> level
        let level: RiskLevel
        if score >= 55 { level = .high }
        else if score >= 25 { level = .medium }
        else { level = .low }

        reasons.append("• คะแนนความเสี่ยง (Heuristic): \(score)")

        return UrlAnalysisResult(
            normalizedUrl: normalized,
            level: level,
            reasons: reasons
        )
    }

    // MARK: - Helpers

    private func normalize(_ raw: String) -> String {
        let s = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")

        guard !s.isEmpty else { return "" }

        // ถ้าไม่มี scheme แต่ดูเหมือนโดเมน ให้เติม https
        if s.lowercased().hasPrefix("http://") || s.lowercased().hasPrefix("https://") {
            return s
        }
        if s.contains(".") && !s.contains(" ") {
            return "https://" + s
        }
        return s
    }

    private func isIPv4(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return false }
        for p in parts {
            guard let n = Int(p), n >= 0 && n <= 255 else { return false }
        }
        return true
    }
}
