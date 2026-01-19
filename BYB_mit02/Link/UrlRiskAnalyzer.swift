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
//  URL-only scanner: normalize + redirect resolve + richer heuristics (no protectedBrands)
//

import Foundation
import FirebaseFirestore


final class UrlRiskAnalyzer {

    // MARK: - Config

    private let maxRedirectHops = 8
    private let networkTimeout: TimeInterval = 8

    private let shortDomains: Set<String> = [
        "bit.ly","t.co","tinyurl.com","goo.gl","rb.gy","is.gd","cutt.ly","ow.ly","rebrand.ly","buff.ly"
    ]

    private let riskyTLDs: Set<String> = [
        "top","xyz","icu","info","click","live","cfd","loan","win","shop","online","site","cyou","monster","gq","tk"
    ]

    private let phishingKeywords: [String] = [
        "login","signin","sign-in","verify","verification","update","secure","confirm","account","wallet",
        "reset","password","passcode","otp","2fa","payment","pay","refund","claim","bonus","reward","prize",
        "suspend","locked","unusual","security","re-auth","authorize","kpay","promptpay"
    ]

    private let riskyFileExtensions: Set<String> = ["apk","exe","msi","dmg","pkg","bat","scr","js","jar","ps1","vbs"]

    // MARK: - Cache (Firestore safe list)

    private var safeHostCache: [String: String] = [:] // host -> displayName
    private let cacheLock = NSLock()

    // MARK: - Public API

    /// Flow: Normalize -> Parse -> Resolve Redirect -> DB Safe -> Heuristic
    func analyzeWithDB(_ raw: String) async -> UrlAnalysisResult {
        let normalized = normalize(raw)

        guard let initialURL = URL(string: normalized) else {
            return UrlAnalysisResult(
                normalizedUrl: normalized,
                level: .high,
                reasons: ["Heuristic: รูปแบบลิงก์ไม่ถูกต้อง", "• URL parse ไม่ได้"],
                finalUrl: nil,
                redirectChain: nil
            )
        }

        // 1) Resolve redirect / expand shortlink
        let resolved = await resolveFinalURL(initialURL)
        let finalURL = resolved.finalURL ?? initialURL
        let chain = resolved.chain

        guard let host = finalURL.host?.lowercased() else {
            return UrlAnalysisResult(
                normalizedUrl: normalized,
                level: .high,
                reasons: [
                    "Heuristic: รูปแบบลิงก์ไม่ถูกต้อง",
                    "• ไม่สามารถแยก host จาก URL ปลายทางได้"
                ],
                finalUrl: resolved.finalURL?.absoluteString,
                redirectChain: chain
            )
        }

        // 2) DB Safe check (ตาม host ปลายทาง)
        if let matchedName = await lookupSafeSiteName(byHost: host) {
            var reasons = [
                "ยืนยันจากฐานข้อมูล: เว็บไซต์ปลอดภัย (SAFE)",
                "• ตรงกับรายการ: \(matchedName)",
                "• โดเมน: \(stripWWW(host))"
            ]
            if chain.count >= 2 {
                reasons.append("• มีการ redirect \(chain.count - 1) ครั้ง แต่ปลายทางอยู่ใน SAFE")
            }

            return UrlAnalysisResult(
                normalizedUrl: normalized,
                level: .low,
                reasons: reasons,
                finalUrl: finalURL.absoluteString,
                redirectChain: chain
            )
        }

        // 3) Heuristic scoring
        return analyzeHeuristic(
            initialNormalized: normalized,
            initialURL: initialURL,
            finalURL: finalURL,
            redirectChain: chain
        )
    }

    // MARK: - Heuristic

    private func analyzeHeuristic(
        initialNormalized: String,
        initialURL: URL,
        finalURL: URL,
        redirectChain: [String]
    ) -> UrlAnalysisResult {

        var score = 0
        var reasons: [String] = ["Heuristic: วิเคราะห์จาก URL (ปลายทางจริง)"]

        let normalizedFinal = finalURL.absoluteString
        let host = (finalURL.host ?? "").lowercased()
        let hostNoWWW = stripWWW(host)
        let scheme = (finalURL.scheme ?? "").lowercased()

        // A) Redirect signals
        if redirectChain.count >= 2 {
            let hops = redirectChain.count - 1
            if hops >= 3 { score += 10 }
            reasons.append("• มีการ redirect \(hops) ครั้ง → ระวัง")

            if let firstHost = URL(string: redirectChain.first ?? "")?.host?.lowercased(),
               shortDomains.contains(stripWWW(firstHost)) {
                score += 20
                reasons.append("• เริ่มจากลิงก์ย่อ (\(stripWWW(firstHost))) → เสี่ยง (ควรตรวจปลายทาง)")
            }
        } else {
            if shortDomains.contains(hostNoWWW) {
                score += 25
                reasons.append("• เป็นลิงก์ย่อ (\(hostNoWWW)) → เสี่ยง (ควรขยายก่อนเปิด)")
            }
        }

        // B) Scheme
        if scheme == "http" {
            score += 25
            reasons.append("• ใช้ HTTP (ไม่เข้ารหัส) → เสี่ยง")
        } else if scheme == "https" {
            reasons.append("• ใช้ HTTPS")
        } else {
            score += 10
            reasons.append("• scheme แปลก/ไม่ระบุ (\"\(scheme)\") → ระวัง")
        }

        // C) @ trick
        if normalizedFinal.contains("@") {
            score += 35
            reasons.append("• พบ '@' ในลิงก์ (อาจหลอกให้เข้าใจผิด) → เสี่ยงสูง")
        }

        // D) IP host
        if isIPv4(hostNoWWW) {
            score += 30
            reasons.append("• ใช้ IP แทนโดเมน (\(hostNoWWW)) → เสี่ยง")
        }

        // E) Punycode / non-ascii / mixed script
        if hostNoWWW.contains("xn--") {
            score += 25
            reasons.append("• โดเมนเป็น Punycode (xn--) อาจเป็นการเลียนแบบชื่อ → เสี่ยง")
        }
        if containsNonASCII(hostNoWWW) {
            score += 12
            reasons.append("• โดเมนมีอักขระ non-ASCII → ระวัง (อาจใช้ตัวอักษรหน้าตาคล้าย)")
        }
        if isMixedScriptLike(hostNoWWW) {
            score += 10
            reasons.append("• โดเมนอาจมีอักษรหลายชุดปนกัน (เลี่ยงการตรวจ) → ระวัง")
        }

        // F) Port
        if let port = finalURL.port, port != 80 && port != 443 {
            score += 15
            reasons.append("• ใช้พอร์ตแปลก :\(port) → เสี่ยง")
        }

        // G) Host complexity
        let dotCount = hostNoWWW.filter { $0 == "." }.count
        if dotCount >= 3 {
            score += 10
            reasons.append("• มี subdomain หลายชั้น (\(dotCount+1) ส่วน) → ระวัง")
        }
        if hostNoWWW.count >= 35 {
            score += 10
            reasons.append("• ชื่อโดเมนยาวผิดปกติ (\(hostNoWWW.count) ตัว) → ระวัง")
        }

        let hyphenCount = hostNoWWW.filter { $0 == "-" }.count
        if hyphenCount >= 4 {
            score += 10
            reasons.append("• มีเครื่องหมาย '-' จำนวนมาก → ระวัง")
        }

        // H) Risky TLD
        if let tld = extractTLD(hostNoWWW), riskyTLDs.contains(tld) {
            score += 10
            reasons.append("• TLD (\(tld)) พบในกลุ่มเสี่ยงบ่อย → ระวัง")
        }

        // I) Digits / lookalike-ish
        let digitCount = hostNoWWW.filter { $0.isNumber }.count
        if digitCount >= 3 {
            score += 8
            reasons.append("• โดเมนมีตัวเลขหลายตัว (\(digitCount)) → ระวัง (อาจเลียนแบบชื่อ)")
        }

        // J) Random-looking label
        if looksRandom(hostNoWWW) {
            score += 10
            reasons.append("• โดเมนดูสุ่ม/ไม่เป็นคำ → ระวัง (มักพบในฟิชชิ่ง)")
        }

        // K) Path/query keywords
        let path = finalURL.path.lowercased()
        let query = (finalURL.query ?? "").lowercased()
        let tokens = (path + " " + query)

        let hits = phishingKeywords.filter { tokens.contains($0) }
        if hits.count >= 3 {
            score += 18
            reasons.append("• พบคำที่มักใช้ในฟิชชิ่งหลายคำ (\(hits.count) คำ) → เสี่ยง")
        } else if hits.count == 2 {
            score += 12
            reasons.append("• พบคำที่มักใช้ในฟิชชิ่ง 2 คำ → ระวัง")
        } else if hits.count == 1, let one = hits.first {
            score += 7
            reasons.append("• พบคำที่มักใช้ในฟิชชิ่ง (\(one)) → ระวัง")
        }

        // L) Query suspiciousness
        if query.count >= 80 {
            score += 10
            reasons.append("• query ยาวมาก (อาจซ่อนข้อมูล/track) → ระวัง")
        }
        if percentEncodingRatio(query) > 0.25 {
            score += 8
            reasons.append("• query มีการ percent-encode สูง (อาจ obfuscate) → ระวัง")
        }
        if containsManyParams(query, threshold: 8) {
            score += 6
            reasons.append("• จำนวนพารามิเตอร์เยอะผิดปกติ → ระวัง")
        }

        // M) Risky downloads
        if let ext = fileExtension(fromPath: path), riskyFileExtensions.contains(ext) {
            score += 20
            reasons.append("• พาธชวนให้ดาวน์โหลดไฟล์ .\(ext) → เสี่ยง")
        }

        // N) Double slashes
        if path.contains("//") {
            score += 6
            reasons.append("• พบ '//' ซ้อนใน path → ระวัง")
        }

        // Level mapping
        let level: RiskLevel
        if score >= 65 { level = .high }
        else if score >= 30 { level = .medium }
        else { level = .low }

        reasons.append("• คะแนนความเสี่ยง (Heuristic): \(score)")

        var outputReasons = ["ไม่มีข้อมูลในระบบ (SAFE list)"] + reasons
        if redirectChain.count >= 2 {
            outputReasons.append("• ปลายทางจริง: \(normalizedFinal)")
        }

        return UrlAnalysisResult(
            normalizedUrl: initialNormalized,
            level: level,
            reasons: outputReasons,
            finalUrl: normalizedFinal,
            redirectChain: redirectChain.isEmpty ? nil : redirectChain
        )
    }

    // MARK: - Redirect Resolver

    private struct RedirectResolveResult {
        let finalURL: URL?
        let chain: [String]
    }

    private func resolveFinalURL(_ url: URL) async -> RedirectResolveResult {
        var chain: [String] = [url.absoluteString]
        var current = url
        var hop = 0

        while hop < maxRedirectHops {
            hop += 1

            // ✅ ห้ามใช้ await กับ ?? (เพราะ RHS เป็น autoclosure)
            let nextURL: URL?
            if let head = await fetchRedirectLocation(for: current, method: "HEAD") {
                nextURL = head
            } else {
                nextURL = await fetchRedirectLocation(for: current, method: "GET")
            }

            guard let next = nextURL else { break }

            let nextStr = next.absoluteString
            if chain.contains(nextStr) { break } // กัน loop

            chain.append(nextStr)
            current = next
        }

        let final = URL(string: chain.last ?? "")
        return RedirectResolveResult(finalURL: final, chain: chain)
    }



    private func fetchRedirectLocation(for url: URL, method: String) async -> URL? {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = networkTimeout
        req.cachePolicy = .reloadIgnoringLocalCacheData

        let session = URLSession(configuration: .ephemeral, delegate: RedirectBlocker(), delegateQueue: nil)

        do {
            let (_, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return nil }

            if (300...399).contains(http.statusCode),
               let loc = http.value(forHTTPHeaderField: "Location"),
               let next = URL(string: loc, relativeTo: url)?.absoluteURL {
                return next
            }
            return nil
        } catch {
            return nil
        }
    }

    private final class RedirectBlocker: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void) {
            completionHandler(nil)
        }
    }

    // MARK: - Firestore lookup (Safe list)

    private func lookupSafeSiteName(byHost host: String) async -> String? {
        let targetHost = stripWWW(host.lowercased())

        // cache
        cacheLock.lock()
        if let cached = safeHostCache[targetHost] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        // NOTE: แนะนำให้เพิ่ม field "host" ใน Firestore เพื่อ query ได้โดยตรง
        do {
            let snap = try await Firestore.firestore()
                .collection("link_confirmed")
                .getDocuments()

            for doc in snap.documents {
                let data = doc.data()
                let displayName = (data["id"] as? String) ?? doc.documentID

                if let urlStr = data["url"] as? String,
                   let u = URL(string: urlStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                   let h = u.host?.lowercased() {
                    if stripWWW(h) == targetHost {
                        cacheLock.lock()
                        safeHostCache[targetHost] = displayName
                        cacheLock.unlock()
                        return displayName
                    }
                }
            }
            return nil
        } catch {
            return nil
        }
    }

    private func stripWWW(_ host: String) -> String {
        host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    // MARK: - Normalize

    private func normalize(_ raw: String) -> String {
        let s = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")

        guard !s.isEmpty else { return "" }

        let lower = s.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return s
        }

        if s.contains(".") && !s.contains(" ") {
            return "https://" + s
        }

        return s
    }

    // MARK: - Helpers

    private func extractTLD(_ host: String) -> String? {
        let parts = host.split(separator: ".")
        guard let last = parts.last, parts.count >= 2 else { return nil }
        return String(last)
    }

    private func containsNonASCII(_ s: String) -> Bool {
        s.unicodeScalars.contains { $0.value > 127 }
    }

    private func isMixedScriptLike(_ host: String) -> Bool {
        var hasASCIIAlpha = false
        var hasNonASCII = false
        for u in host.unicodeScalars {
            if u.value <= 127, CharacterSet.letters.contains(u) { hasASCIIAlpha = true }
            if u.value > 127 { hasNonASCII = true }
            if hasASCIIAlpha && hasNonASCII { return true }
        }
        return false
    }

    private func fileExtension(fromPath path: String) -> String? {
        guard let last = path.split(separator: "/").last else { return nil }
        let comps = last.split(separator: ".")
        guard comps.count >= 2, let ext = comps.last else { return nil }
        return String(ext).lowercased()
    }

    private func percentEncodingRatio(_ s: String) -> Double {
        guard !s.isEmpty else { return 0 }
        let pct = s.filter { $0 == "%" }.count
        return Double(pct) / Double(s.count)
    }

    private func containsManyParams(_ query: String, threshold: Int) -> Bool {
        guard !query.isEmpty else { return false }
        let eq = query.filter { $0 == "=" }.count
        return eq >= threshold
    }

    private func looksRandom(_ host: String) -> Bool {
        let labels = host.split(separator: ".")
        guard let main = labels.first else { return false }
        let s = String(main)
        if s.count < 12 { return false }

        let vowels = "aeiou"
        let vowelCount = s.lowercased().filter { vowels.contains($0) }.count
        let digitCount = s.filter { $0.isNumber }.count
        let letterCount = s.filter { $0.isLetter }.count

        if letterCount > 0 && Double(vowelCount) / Double(letterCount) < 0.18 && s.count >= 14 {
            return true
        }
        if digitCount >= 5 { return true }
        if hasRepeatedRun(s, minRun: 4) { return true }

        return false
    }

    private func hasRepeatedRun(_ s: String, minRun: Int) -> Bool {
        var last: Character?
        var run = 0
        for c in s {
            if c == last { run += 1 } else { run = 1; last = c }
            if run >= minRun { return true }
        }
        return false
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

