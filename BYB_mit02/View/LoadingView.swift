//
//  LoadingView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("NOW LOADING")
                .font(.title2).bold()

            Text("กำลังตรวจสอบข้อมูลที่คุณส่งว่าเป็นสแกมหรือไม่")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            ProgressView()
                .scaleEffect(1.6)
                .padding(.top, 24)

            Spacer()
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
