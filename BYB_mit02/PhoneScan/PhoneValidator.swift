//
//  PhoneNumberValidator.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 13/1/2569 BE.
//

import Foundation

struct PhoneNumberValidator {

    struct PhoneCheckResult {
        let cleanedNumber: String
        let origin: String          // พื้นที่/ประเทศ
        let carrier: String         // เครือข่าย
        let numberType: String      // ประเภทเบอร์
        let hasSuspiciousPattern: Bool
        let isVerifiedService: Bool
    }

    func validateNumber(_ input: String) -> PhoneCheckResult? {

        // 1) Cleanup
        let cleaned = input.filter { "0123456789+".contains($0) }
        guard !cleaned.isEmpty else { return nil }

        var origin = "ไม่ระบุพื้นที่"
        var carrier = "ไม่ระบุเครือข่าย"
        var numberType = "หมายเลขทั่วไป"
        var isVerified = false

        // 2) Area / Origin
        if cleaned.hasPrefix("02") {
            origin = "กรุงเทพฯและปริมณฑล"
            numberType = "เบอร์บ้าน"
        } else if cleaned.hasPrefix("053") {
            origin = "เชียงใหม่/ภาคเหนือ"
            numberType = "เบอร์บ้าน"
        } else if cleaned.hasPrefix("074") {
            origin = "สงขลา/ภาคใต้"
            numberType = "เบอร์บ้าน"
        }

        // 3) Carrier
        let prefix3 = String(cleaned.prefix(3))
        let ais = ["061", "062", "081", "082", "092", "098"]
        let trueDtac = ["064", "083", "084", "095", "096"]

        if ais.contains(prefix3) {
            carrier = "AIS"
            numberType = "มือถือ"
        } else if trueDtac.contains(prefix3) {
            carrier = "True/dtac"
            numberType = "มือถือ"
        }

        // 4) International
        if cleaned.hasPrefix("+") && !cleaned.hasPrefix("+66") {
            origin = "ต่างประเทศ (ความเสี่ยงสูง)"
            numberType = "International Call"
        }

        // 5) Verified services
        let whiteList = [
            "191": "เหตุด่วนเหตุร้าย",
            "1599": "สายด่วนตำรวจ",
            "1441": "ตำรวจไซเบอร์"
        ]

        if let serviceName = whiteList[cleaned] {
            isVerified = true
            numberType = "หน่วยงานรัฐ: \(serviceName)"
        }

        // 6) Anomaly detection
        let uniqueDigits = Set(cleaned.filter { $0.isNumber })
        let hasSuspiciousPattern = cleaned.count >= 9 && uniqueDigits.count <= 2

        return PhoneCheckResult(
            cleanedNumber: cleaned,
            origin: origin,
            carrier: carrier,
            numberType: numberType,
            hasSuspiciousPattern: hasSuspiciousPattern,
            isVerifiedService: isVerified
        )
    }
}
