//
//  RecentSection.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 11/1/2569 BE.
//

import SwiftUI

struct RecentSection: View {
    let items: [ScanResult]
    let onClear: () -> Void
    let onTap: (ScanResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Spacer()
                if !items.isEmpty {
                    Button(action: onClear) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.caption2).bold()
                        .foregroundColor(.red.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.10))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                }
            }

            VStack(spacing: 10) {
                ForEach(items.prefix(5)) { r in
                    let isUnknown = r.reasons.contains("ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์")
                    let isNoData = r.reasons.contains(RiskService.noDataReason)

                    Button { onTap(r) } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .frame(width: 14, height: 14)
                                .foregroundStyle((isUnknown || isNoData) ? .gray : dotColor(for: r.level))
                                .opacity(0.9)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.input).font(.subheadline).bold().lineLimit(1)
                                Text(r.timestamp.formatted(date: .numeric, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isUnknown {
                                pillGray("UNKNOWN")
                            } else if isNoData {
                                pillGray("NO DATA")
                            } else {
                                StatusPill(level: r.level) // ใช้ตัวเดิมในโปรเจกต์
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill((isUnknown || isNoData) ? Color.gray.opacity(0.08) : background(for: r.level))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke((isUnknown || isNoData) ? Color.gray.opacity(0.2) : border(for: r.level), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }

                if items.isEmpty {
                    Text("ยังไม่มีประวัติการสแกน")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private func pillGray(_ text: String) -> some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.15))
            .foregroundStyle(.gray)
            .cornerRadius(10)
    }

    private func dotColor(for level: RiskLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func background(for level: RiskLevel) -> Color {
        switch level {
        case .low: return Color.green.opacity(0.12)
        case .medium: return Color.orange.opacity(0.14)
        case .high: return Color.red.opacity(0.14)
        }
    }

    private func border(for level: RiskLevel) -> Color {
        switch level {
        case .low: return Color.green.opacity(0.35)
        case .medium: return Color.orange.opacity(0.35)
        case .high: return Color.red.opacity(0.35)
        }
    }
}
