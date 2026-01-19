//
//  HistoryView.swift
//  BYB_mit02
//
//
//  ScanHistoryView.swift
//  BYB_mit02
//

import SwiftUI

struct ScanHistoryView: View {
    @ObservedObject var historyStore: ScanHistoryStore
    var onSelect: (ScanResult) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if historyStore.items.isEmpty {
                    Text("ยังไม่มีประวัติการสแกน")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                } else {
                    ForEach(historyStore.items) { r in
                        HistoryCard(
                            result: r,
                            onDelete: { historyStore.delete(r) },
                            onTap: { onSelect(r) }
                        )
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { historyStore.clear() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("กดเพื่อล้างข้อมูล")
                    }
                }
                .disabled(historyStore.items.isEmpty)
            }
        }
    }
}

private struct HistoryCard: View {
    let result: ScanResult
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        let isUnknown = result.reasons.contains("ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์")
        let isNoData = result.reasons.contains(RiskService.noDataReason)

        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .frame(width: 14, height: 14)
                    .foregroundStyle((isUnknown || isNoData) ? .gray : dotColor)
                    .opacity(0.9)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.input)
                        .font(.subheadline).bold()
                        .lineLimit(1)

                    Text(result.timestamp.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isUnknown {
                    pillGray("UNKNOWN")
                } else if isNoData {
                    pillGray("NO DATA")
                } else {
                    StatusPill(riskLevel: result.riskLevel)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(10)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill((isUnknown || isNoData) ? Color.gray.opacity(0.08) : bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke((isUnknown || isNoData) ? Color.gray.opacity(0.2) : borderColor, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
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

    private var dotColor: Color {
        switch result.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var bgColor: Color {
        switch result.riskLevel {
        case .low: return Color.green.opacity(0.12)
        case .medium: return Color.orange.opacity(0.14)
        case .high: return Color.red.opacity(0.14)
        }
    }

    private var borderColor: Color {
        switch result.riskLevel {
        case .low: return Color.green.opacity(0.35)
        case .medium: return Color.orange.opacity(0.35)
        case .high: return Color.red.opacity(0.35)
        }
    }
}
