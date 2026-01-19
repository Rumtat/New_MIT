//
//  RiskService.swift
//  BYB_mit02
//

import Foundation

final class RiskService {
    static let noDataReason = "ไม่มีข้อมูลในระบบ"

    private let repository: ScamRepository

    init(repository: ScamRepository) {
        self.repository = repository
    }

    // Database-only scan
    func scanDatabaseOnly(type: ScanType, input: String) async -> ScanResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lookupType: ScanType = (type == .qr) ? .url : type
        let entries = await repository.findEntries(type: lookupType, input: trimmed)

        guard !entries.isEmpty else {
            return ScanResult(
                type: type,
                input: trimmed,
                riskLevel: .low,
                reasons: [Self.noDataReason]
            )
        }

        let dbLevel = entries
            .map { Self.riskLevelFromLabel($0.label) }
            .max() ?? .high

        let reasons = entries.map {
            $0.note.isEmpty
            ? "ฐานข้อมูลมิจฉาชีพ: \($0.label)"
            : "ฐานข้อมูลมิจฉาชีพ: \($0.label) — \($0.note)"
        }

        return ScanResult(
            type: type,
            input: trimmed,
            riskLevel: dbLevel,
            reasons: reasons.uniquedPreservingOrder()
        )
    }

    func scan(type: ScanType, input: String) async -> ScanResult {
        await scanDatabaseOnly(type: type, input: input)
    }

    private static func riskLevelFromLabel(_ label: String) -> RiskLevel {
        let s = label.lowercased()
        if s.contains("high") { return .high }
        if s.contains("medium") { return .medium }
        if s.contains("low") { return .low }
        return .high
    }
}
