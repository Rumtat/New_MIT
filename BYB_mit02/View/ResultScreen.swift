//
//  Result Screen.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import SwiftUI

struct ResultView: View {
    let result: ScanResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 16) {
                Text(result.level == .low ? "This Link is safe!" : "WARNING\nThis link could be dangerous!")
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)

                Button("Return to main menu") {
                    dismiss() // กลับหน้าหลัก
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 12)

                Spacer()
            }
            .padding(.top, 80)
            .padding(.horizontal, 20)
        }
    }

    private var backgroundColor: Color {
        switch result.level {
        case .low: return Color.green.opacity(0.25)   // SAFE = เขียว
        case .medium: return Color.orange.opacity(0.25)
        case .high: return Color.red.opacity(0.25)    // SCAM = แดง
        }
    }
}
