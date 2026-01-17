//
//  PhoneValidator.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 13/1/2569 BE.
//


import Foundation

struct PhoneValidator {
    struct PhoneMetadata {
        let cleanedNumber: String
        let origin: String          // เช็คถิ่นกำเนิด (จังหวัด/ประเทศ)
        let carrier: String         // เช็คเครือข่าย
        let typeDescription: String // ประเภท (มือถือ/บ้าน/เบอร์สั้น)
        let isHighRiskPattern: Bool // Anomaly Detection
        let isVerifiedService: Bool // Trust Verification
    }

    func validate(_ input: String) -> PhoneMetadata? {
        // --- 1. Human Error Prevention (Auto-Cleanup) ---
        let cleaned = input.filter { "0123456789+".contains($0) }
        guard !cleaned.isEmpty else { return nil }

        // --- 2. Origin & Telecom Check (เช็คพื้นที่และเครือข่าย) ---
        var origin = "ไม่ระบุพื้นที่"
        var carrier = "ไม่ระบุเครือข่าย"
        var typeDesc = "หมายเลขทั่วไป"
        var isVerified = false

        // เช็คเบอร์บ้าน (รหัสจังหวัด)
        if cleaned.hasPrefix("02") { origin = "กรุงเทพฯและปริมณฑล"; typeDesc = "เบอร์บ้าน" }
        else if cleaned.hasPrefix("053") { origin = "เชียงใหม่/ภาคเหนือ"; typeDesc = "เบอร์บ้าน" }
        else if cleaned.hasPrefix("074") { origin = "สงขลา/ภาคใต้"; typeDesc = "เบอร์บ้าน" }
        
        // เช็คเครือข่ายมือถือ (Carrier Lookup - ตัวอย่าง)
        let prefix3 = String(cleaned.prefix(3))
        let ais = ["061", "062", "081", "082", "092", "098"]
        let trueDtac = ["064", "083", "084", "095", "096"]
        
        if ais.contains(prefix3) { carrier = "AIS"; typeDesc = "มือถือ" }
        else if trueDtac.contains(prefix3) { carrier = "True/dtac"; typeDesc = "มือถือ" }

        // เช็ครหัสประเทศ (International)
        if cleaned.hasPrefix("+") && !cleaned.hasPrefix("+66") {
            origin = "ต่างประเทศ (ความเสี่ยงสูง)"
            typeDesc = "International Call"
        }

        // --- 3. Trust Verification (เบอร์หน่วยงาน) ---
        let whiteList = ["191": "เหตุด่วนเหตุร้าย", "1599": "สายด่วนตำรวจ", "1441": "ตำรวจไซเบอร์"]
        if let serviceName = whiteList[cleaned] {
            isVerified = true
            typeDesc = "หน่วยงานรัฐ: \(serviceName)"
        }

        // --- 4. Anomaly Detection (เลขซ้ำ/เลขเรียง) ---
        let uniqueDigits = Set(cleaned.filter { $0.isNumber })
        let isAnomaly = cleaned.count >= 9 && uniqueDigits.count <= 2 // เช่น 088-888-8888

        return PhoneMetadata(
            cleanedNumber: cleaned,
            origin: origin,
            carrier: carrier,
            typeDescription: typeDesc,
            isHighRiskPattern: isAnomaly,
            isVerifiedService: isVerified
        )
    }
}
