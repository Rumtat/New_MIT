//
//  Models.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import Foundation

// MARK: - Scan Type

enum ScanType: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }

    // Core scan types
    case url, phone, bank, qr, sms

    // Legacy / existing screens
    case text, report, faceScan
}

// MARK: - Bank Search

enum BankSearchMode: String, CaseIterable, Codable {
    case byAccount = "By Account"
    case byName = "By Name"
}

// MARK: - Risk Level (data-level only)

enum RiskLevel: String, Codable, Comparable {
    case low, medium, high

    private var rank: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

// MARK: - Scan Result

struct ScanResult: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ScanType
    let input: String
    let riskLevel: RiskLevel
    let reasons: [String]
    let timestamp: Date

    // Optional metadata
    var bankName: String?
    var ownerName: String?

    init(
        type: ScanType,
        input: String,
        riskLevel: RiskLevel,
        reasons: [String]
    ) {
        self.id = UUID()
        self.type = type
        self.input = input
        self.riskLevel = riskLevel
        self.reasons = reasons
        self.timestamp = Date()
    }
}

// MARK: - Bank Blacklist Entry

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

// MARK: - Scam Entry

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

// MARK: - URL Analysis Result (moved from UrlRiskAnalyzer.swift)

struct UrlAnalysisResult {
    let normalizedUrl: String
    let level: RiskLevel
    let reasons: [String]
    let finalUrl: String?
    let redirectChain: [String]?
}

// MARK: - SMS Scan Result (moved from SmsRiskAnalyzer.swift)

struct SmsScanResult {
    let riskLevel: RiskLevel
    let reasons: [String]
    let urls: [String]
    let phoneNumbers: [String]
    let bankAccounts: [String]
}

// MARK: - Report Case (moved from Reportcase.swift)

struct ReportCase: Codable {
    let fullName: String
    let phoneNumber: String
    let bankAccount: String
    let email: String
    let type: String
    let date: Date
    let amount: Double
    let details: String

    // แบบย่อสำหรับใช้ใน Service เดิม
    init(
        type: String,
        value: String,
        details: String,
        fullName: String = "",
        phoneNumber: String = "",
        bankAccount: String = "",
        email: String = "",
        date: Date = Date(),
        amount: Double = 0
    ) {
        self.type = type
        self.value = value
        self.details = details
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.bankAccount = bankAccount
        self.email = email
        self.date = date
        self.amount = amount
    }

    private let value: String // backward compatibility
}

// MARK: - Onboarding Step (moved from OnboardingStep.swift)

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let imageName: String
    var primaryButtonTitle: String? = nil
}

// MARK: - Helpers

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
