//
//  ReportSuccessView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 11/1/2569 BE.
//

import SwiftUI // ✅ บรรทัดนี้สำคัญมาก ห้ามลืมเด็ดขาด

struct ReportSuccessView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon Success แบบพรีเมียม
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: 16) {
                Text("ส่งรายงานสำเร็จ")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.10, green: 0.16, blue: 0.35))
                
                Text("ขอบคุณที่ร่วมเป็นส่วนหนึ่งในการป้องกันภัยสแกม\nข้อมูลของคุณมีค่าอย่างมากต่อสังคม")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button {
                // ✅ กลับหน้าแรกสุด
                isPresented = false // ปิดสถานะการนำทางใน Stack
                NotificationCenter.default.post(name: NSNotification.Name("PopToRoot"), object: nil) // ส่งสัญญาณกลับหน้าแรก
                dismiss() // ปิดหน้าปัจจุบัน
            } label: {
                Text("ตกลง")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.12, green: 0.19, blue: 0.55), Color(red: 0.17, green: 0.30, blue: 0.78)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(red: 0.17, green: 0.30, blue: 0.78).opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .background(Color.white.ignoresSafeArea())
    }
}
