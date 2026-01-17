//
//  HeaderBar.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 11/1/2569 BE.
//

import SwiftUI

struct HeaderBar: View {
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    .frame(width: 42, height: 42)
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(.white)
            }

            Text("BYEMIT")
                .font(.title3).bold()
                .foregroundStyle(.white)

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(.trailing, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.19, blue: 0.55), Color(red: 0.18, green: 0.33, blue: 0.78)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

