//
//  BankResultView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//

import SwiftUI

struct BankResultView: View {
    // ✅ ชื่อใหม่
    let scanResult: ScanResult

    // ✅ คง initializer เดิมไว้ กัน call site พัง
    init(result: ScanResult) {
        self.scanResult = result
    }

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

    private var displayNameLine: String {
        let parts = [scanResult.bankName, scanResult.ownerName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? "" : parts.joined(separator: " • ")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                VStack(spacing: 10) {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Text(statusTitle)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(statusColor)

                    Text(scanResult.input)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.secondary)

                    if !displayNameLine.isEmpty {
                        Text(displayNameLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 10)

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

                VStack(alignment: .leading, spacing: 10) {
                    Text("ผลการวิเคราะห์ความเสี่ยง")
                        .font(.headline)

                    HStack(spacing: 10) {
                        Image(systemName: (isNoData || isUnverifiable) ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
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
        .navigationTitle("ผลการสแกนบัญชี")
        .navigationBarTitleDisplayMode(.inline)
    }
}
