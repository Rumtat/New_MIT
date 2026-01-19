//
//  ThaiResultView.swift
//  BYB_mit02
//

import SwiftUI

struct ThaiResultView: View {
    let scanResult: ScanResult

    // MARK: - State helpers

    private var isNoData: Bool {
        // ✅ รองรับทั้งกรณีที่ reason ตรงกับ constant และกรณีที่มีคำต่อท้าย เช่น "(SAFE list)"
        scanResult.reasons.contains(where: { r in
            let s = r.trimmingCharacters(in: .whitespacesAndNewlines)
            return s == RiskService.noDataReason
            || s.contains(RiskService.noDataReason)
            || s.hasPrefix("ไม่มีข้อมูลในระบบ")
            || s.contains("ไม่มีข้อมูลในระบบ")
        })
    }

    private var isUnknown: Bool {
        scanResult.reasons.contains("ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์")
    }

    private var accentColor: Color {
        if isUnknown || isNoData { return .gray }
        switch scanResult.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var statusTitle: String {
        if isUnknown { return "ไม่สามารถตรวจสอบได้" }
        if isNoData { return "ไม่มีข้อมูลในระบบ" }
        switch scanResult.riskLevel {
        case .low: return "ปลอดภัย"
        case .medium: return "มีความเสี่ยง"
        case .high: return "ไม่ปลอดภัย"
        }
    }

    private var iconName: String {
        if isUnknown || isNoData { return "questionmark.circle.fill" }
        switch scanResult.riskLevel {
        case .low: return "checkmark.seal.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.octagon.fill"
        }
    }

    private var shouldShowLinkPreview: Bool {
        scanResult.type == .url || scanResult.type == .qr
    }

    // MARK: - Deep Info parsing

    private struct BulletItem: Identifiable {
        let id = UUID()
        let text: String
        let indent: Int
    }

    private var deepInfoItems: [BulletItem] {
        var items: [BulletItem] = []

        for reason in scanResult.reasons {
            let line = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("Heuristic:") {
                items.append(.init(text: line, indent: 0))
                continue
            }

            if line.hasPrefix("•") {
                let cleaned = line
                    .replacingOccurrences(of: "•", with: "")
                    .trimmingCharacters(in: .whitespaces)
                items.append(.init(text: cleaned, indent: 1))
                continue
            }

            items.append(.init(text: line, indent: 0))
        }

        return items
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                VStack(spacing: 10) {
                    Image(systemName: iconName)
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(accentColor)

                    Text(statusTitle)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(scanResult.input)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 18)

                if shouldShowLinkPreview {
                    LinkPreviewView(urlString: scanResult.input)
                        .padding(.horizontal, 16)
                }

                if isNoData && (scanResult.riskLevel == .medium || scanResult.riskLevel == .high) {
                    RiskWarningBanner(
                        title: "เตือนความเสี่ยงจากรูปแบบ",
                        message: "แม้ไม่มีข้อมูลในระบบ แต่รูปแบบเข้าข่ายความเสี่ยง \(scanResult.riskLevel == .high ? "สูง" : "ปานกลาง") — โปรดหลีกเลี่ยงการกรอกข้อมูลหรือ OTP และตรวจสอบแหล่งที่มา",
                        riskLevel: scanResult.riskLevel
                    )
                    .padding(.horizontal, 16)
                }

                if !deepInfoItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.blue)
                            Text("ข้อมูลเชิงลึก")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.blue)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(deepInfoItems) { item in
                                BulletRow(text: item.text, indent: item.indent)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("ผลการตรวจสอบ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BulletRow: View {
    let text: String
    let indent: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body.weight(.bold))
                .padding(.leading, CGFloat(indent) * 18)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}
