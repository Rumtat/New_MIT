//
//  StatusPill.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 11/1/2569 BE.
//


import SwiftUI

struct StatusPill: View {
    let level: RiskLevel

    var body: some View {
        Text(text)
            .font(.caption).bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.22))
            )
            .foregroundStyle(color)
    }

    private var text: String {
        switch level {
        case .low: return "SAFE"
        case .medium: return "RISK"
        case .high: return "SCAM"
        }
    }

    private var color: Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
