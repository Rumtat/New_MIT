//
//  RiskService.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//


import Foundation

final class RiskService {
    static let noDataReason = "ไม่มีข้อมูลในระบบ"

    private let repository: ScamRepository

    init(repository: ScamRepository) {
        self.repository = repository
    }

    /// คืนค่าเฉพาะผลจากฐานข้อมูล (DB)
    /// - ถ้าพบใน DB -> reasons เป็นหลักฐาน DB (ไม่ใส่ noDataReason)
    /// - ถ้าไม่พบใน DB -> reasons = [noDataReason]
    func scanDBOnly(type: ScanType, input: String) async -> ScanResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if type == .faceScan || type == .report {
            return ScanResult(type: type, input: trimmed, level: .low, reasons: [])
        }

        let lookupType: ScanType = (type == .qr) ? .url : type
        let matches = await repository.findMatches(type: lookupType, input: trimmed)

        if !matches.isEmpty {
            // พบใน DB (ให้เป็น high)
            let reasons = matches.map { "ฐานข้อมูลมิจฉาชีพ: \($0.label)" }
            return ScanResult(type: type, input: trimmed, level: .high, reasons: reasons)
        }

        // ไม่พบใน DB -> flag no data
        return ScanResult(type: type, input: trimmed, level: .low, reasons: [Self.noDataReason])
    }
}
