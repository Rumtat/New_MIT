//
//  PhoneResultView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 13/1/2569 BE.
//

import SwiftUI

struct PhoneResultView: View {
    let scanResult: ScanResult

    private var isNoData: Bool {
        scanResult.reasons.contains(RiskService.noDataReason)
    }

    private var isUnverifiable: Bool {
        scanResult.reasons.contains("ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์")
    }

    private var statusColor: Color {
        if isNoData || isUnverifiable { return .gray }
        switch scanResult.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var statusTitle: String {
        if isUnverifiable { return "ไม่สามารถตรวจสอบได้" }
        if isNoData { return "ไม่มีข้อมูลในระบบ" }
        switch scanResult.riskLevel {
        case .low: return "ปลอดภัย"
        case .medium: return "มีความเสี่ยง"
        case .high: return "ไม่ปลอดภัย"
        }
    }

    private var statusBadgeText: String {
        if isUnverifiable { return "UNKNOWN" }
        if isNoData { return "NO DATA" }
        switch scanResult.riskLevel {
        case .low: return "SAFE"
        case .medium: return "RISK"
        case .high: return "SCAM"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Top status
                VStack(spacing: 10) {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Text(statusTitle)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(statusColor)

                    Text(scanResult.input)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(statusBadgeText)
                        .font(.caption).bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(isNoData || isUnverifiable ? 0.15 : 0.0))
                        .foregroundStyle((isNoData || isUnverifiable) ? Color.gray : statusColor)
                        .cornerRadius(10)
                        .opacity((isNoData || isUnverifiable) ? 1 : 0)
                }
                .padding(.top, 10)

                // ข้อมูลเชิงลึก
                if !scanResult.reasons.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundStyle(Color.blue)
                            Text("ข้อมูลเชิงลึก")
                                .font(.headline)
                                .foregroundStyle(Color.blue)
                        }

                        Divider()

                        ForEach(scanResult.reasons.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 10) {
                                Text("•")
                                Text(scanResult.reasons[i])
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.08))
                    )
                    .padding(.horizontal, 16)
                }

                // ผลการวิเคราะห์ความเสี่ยง
                VStack(alignment: .leading, spacing: 10) {
                    Text("ผลการวิเคราะห์ความเสี่ยง")
                        .font(.headline)

                    HStack(spacing: 10) {
                        Image(systemName: (isNoData || isUnverifiable)
                              ? "exclamationmark.triangle.fill"
                              : "checkmark.seal.fill")
                            .foregroundStyle(statusColor)

                        Text(isNoData ? RiskService.noDataReason : statusTitle)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("ผลการสแกนเบอร์")
        .navigationBarTitleDisplayMode(.inline)
    }
}
