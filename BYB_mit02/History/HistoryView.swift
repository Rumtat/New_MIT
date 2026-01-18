//
//  HistoryView.swift
//  BYB_mit02
//

import SwiftUI

@MainActor
final class ScanHistory: ObservableObject {
    @Published private(set) var items: [ScanResult] = []

    private let key = "scan_history_v1"

    init() { load() }

    func add(_ result: ScanResult) {
        withAnimation(.snappy) {
            items.insert(result, at: 0)
            if items.count > 80 { items = Array(items.prefix(80)) }
        }
        save()
    }

    func clear() {
        withAnimation(.snappy) { items.removeAll() }
        save()
    }

    func delete(_ item: ScanResult) {
        withAnimation(.snappy) { items.removeAll { $0.id == item.id } }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ScanResult].self, from: data)
        else { return }
        items = decoded
    }
}

struct HistoryView: View {
    @ObservedObject var history: ScanHistory
    var onTap: (ScanResult) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if history.items.isEmpty {
                    Text("ยังไม่มีประวัติการสแกน")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                } else {
                    ForEach(history.items) { r in
                        HistoryCard(
                            result: r,
                            onDelete: { history.delete(r) },
                            onTap: { onTap(r) }
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
                Button(role: .destructive) { history.clear() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                }
                .disabled(history.items.isEmpty)
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
                    StatusPill(level: result.level) // ใช้ตัวเดิมที่มีอยู่แล้วในโปรเจกต์
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
        switch result.level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var bgColor: Color {
        switch result.level {
        case .low: return Color.green.opacity(0.12)
        case .medium: return Color.orange.opacity(0.14)
        case .high: return Color.red.opacity(0.14)
        }
    }

    private var borderColor: Color {
        switch result.level {
        case .low: return Color.green.opacity(0.35)
        case .medium: return Color.orange.opacity(0.35)
        case .high: return Color.red.opacity(0.35)
        }
    }
}
