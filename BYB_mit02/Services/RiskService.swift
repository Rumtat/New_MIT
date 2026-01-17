//
//  RiskService.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import Foundation

final class RiskService {
    private let repository: ScamRepository

    init(repository: ScamRepository) {
        self.repository = repository
    }

    func scan(type: ScanType, input: String) async -> ScanResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if type == .faceScan || type == .report {
            return ScanResult(type: type, input: trimmed, level: .low, reasons: [])
        }

        // QR ใช้ฐานข้อมูลแบบ URL
        let lookupType: ScanType = (type == .qr) ? .url : type
        let matches = await repository.findMatches(type: lookupType, input: trimmed)

        if !matches.isEmpty {
            return ScanResult(
                type: type,
                input: trimmed,
                level: .high,
                reasons: matches.map { "ฐานข้อมูลมิจฉาชีพ: \($0.label)" }
            )
        }

        return ScanResult(
            type: type,
            input: trimmed,
            level: .low,
            reasons: ["ไม่พบข้อมูลมิจฉาชีพ"]
        )
    }
}
