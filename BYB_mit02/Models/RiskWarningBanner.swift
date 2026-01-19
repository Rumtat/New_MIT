//
//  RiskWarningBanner.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 18/1/2569 BE.
//

import SwiftUI

struct RiskWarningBanner: View {
    let title: String
    let message: String
    let riskLevel: RiskLevel

    private var accentColor: Color {
        switch riskLevel {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var icon: String {
        switch riskLevel {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.octagon.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(accentColor)
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accentColor.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
