//
//  PhoneResultView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 13/1/2569 BE.
//

import SwiftUI

struct PhoneResultView: View {
    let result: ScanResult

    private var isNoData: Bool {
        result.reasons.contains(RiskService.noDataReason)
    }

    private var isUnknown: Bool {
        result.reasons.contains("ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์")
    }

    private var accent: Color {
        if isNoData || isUnknown { return .gray }
        switch result.level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var headline: String {
        if isUnknown { return "ไม่สามารถตรวจสอบได้" }
        if isNoData { return "ไม่มีข้อมูลในระบบ" }
        switch result.level {
        case .low: return "ปลอดภัย"
        case .medium: return "มีความเสี่ยง"
        case .high: return "ไม่ปลอดภัย"
        }
    }

    private var pillText: String {
        if isUnknown { return "UNKNOWN" }
        if isNoData { return "NO DATA" }
        switch result.level {
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
                        .fill(accent.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Text(headline)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(accent)

                    Text(result.input)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(pillText)
                        .font(.caption).bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(isNoData || isUnknown ? 0.15 : 0.0))
                        .foregroundStyle((isNoData || isUnknown) ? Color.gray : accent)
                        .cornerRadius(10)
                        .opacity((isNoData || isUnknown) ? 1 : 0) // ป้ายบนสุดโชว์เฉพาะ NO DATA/UNKNOWN
                }
                .padding(.top, 10)

                // ข้อมูลเชิงลึก (heuristic)
                if !result.reasons.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundStyle(Color.blue)
                            Text("ข้อมูลเชิงลึก")
                                .font(.headline)
                                .foregroundStyle(Color.blue)
                        }

                        Divider()

                        ForEach(result.reasons.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 10) {
                                Text("•")
                                Text(result.reasons[i])
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

                // ผลการวิเคราะห์ความเสี่ยง (แสดง NO DATA ชัด ๆ)
                VStack(alignment: .leading, spacing: 10) {
                    Text("ผลการวิเคราะห์ความเสี่ยง")
                        .font(.headline)

                    HStack(spacing: 10) {
                        Image(systemName: (isNoData || isUnknown) ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .foregroundStyle(accent)

                        Text(isNoData ? RiskService.noDataReason : headline)
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
