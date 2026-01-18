//
//  Models.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import Foundation

enum ScanType: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }

    // Core scan types (ตามเอกสาร)
    case url, phone, bank, qr, sms

    // Legacy / existing screens (ยังคงไว้เพื่อไม่ให้ UI เดิมพัง)
    case text, report, faceScan
}

enum BankSearchMode: String, CaseIterable, Codable {
    case byAccount = "By Account"
    case byName = "By Name"
}

enum RiskLevel: String, Codable {
    case low, medium, high

    var displayTitle: String {
        switch self {
        case .low: return "ปลอดภัย"
        case .medium: return "มีความเสี่ยง"
        case .high: return "ไม่ปลอดภัย / มิจฉาชีพ"
        }
    }
}

extension RiskLevel: Comparable {
    private var rank: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool { lhs.rank < rhs.rank }
}

struct ScanResult: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ScanType
    let input: String
    let level: RiskLevel
    let reasons: [String]
    let timestamp: Date
    var bankName: String?
    var ownerName: String?

    init(type: ScanType, input: String, level: RiskLevel, reasons: [String]) {
        self.id = UUID()
        self.type = type
        self.input = input
        self.level = level
        self.reasons = reasons
        self.timestamp = Date()
    }

    var displayTitle: String {
        switch level {
        case .low: return "ปลอดภัย"
        case .medium: return "มีความเสี่ยง"
        case .high: return "ไม่ปลอดภัย"
        }
    }
}

struct BankBlacklistEntry: Codable, Identifiable {
    var id: String
    let bank_name: String?
    let level: String?
    let name: String?
    let reasons: [String]?
}

extension BankBlacklistEntry {
    var riskLevel: RiskLevel {
        switch (level ?? "").lowercased() {
        case "high": return .high
        case "medium": return .medium
        default: return .low
        }
    }
}
struct ScamEntry: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case phone
        case bankAccount
        case name
        case url
        case sms
        case qr
    }

    let id: UUID
    let kind: Kind
    let value: String
    let label: String
    let note: String

    init(kind: Kind, value: String, label: String, note: String) {
        self.id = UUID()
        self.kind = kind
        self.value = value
        self.label = label
        self.note = note
    }
}

extension Array where Element: Hashable {
    func uniquedPreservingOrder() -> [Element] {
        var seen = Set<Element>()
        var out: [Element] = []
        out.reserveCapacity(count)
        for e in self {
            if seen.insert(e).inserted {
                out.append(e)
            }
        }
        return out
    }
}

