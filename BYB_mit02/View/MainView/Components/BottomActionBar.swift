//
//  BottomActionBar.swift
//  BYB_mit02
//

import SwiftUI

struct BottomActionBar: View {
    let selected: ScanType
    let onSelect: (ScanType) -> Void
    let onReport: () -> Void

    var body: some View {
        HStack {
            ActionItem(icon: "magnifyingglass", isSelected: selected == .url) { onSelect(.url) }
            Spacer()

            ActionItem(icon: "phone.fill", isSelected: selected == .phone) { onSelect(.phone) }
            Spacer()

            ActionItem(icon: "banknote.fill", isSelected: selected == .bank) { onSelect(.bank) }
            Spacer()

            ActionItem(icon: "qrcode.viewfinder", isSelected: selected == .qr) { onSelect(.qr) }
            Spacer()

            Menu {
                Button { onSelect(.sms) } label: {
                    Label("สแกน SMS / ข้อความ", systemImage: "message.fill")
                }

                Button { onSelect(.faceScan) } label: {
                    Label("สแกนรูป (Image)", systemImage: "photo.fill")
                }

                Button { onReport() } label: {
                    Label("แจ้งรายงานมิจฉาชีพ", systemImage: "exclamationmark.bubble.fill")
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(Color.white.opacity(0.08)))

                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.19, blue: 0.55),
                    Color(red: 0.18, green: 0.33, blue: 0.78)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private struct ActionItem: View {
        let icon: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(isSelected ? Color.white.opacity(0.18) : Color.clear))

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
