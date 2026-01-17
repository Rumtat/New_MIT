//
//  OnboardingStep.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//

import SwiftUI

// ✅ 1. ย้ายโครงสร้างข้อมูลออกมาไว้ด้านนอกเพื่อให้ทุกส่วนเรียกใช้ได้
struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct UserGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentStep = 0
    
    // ✅ 2. ประกาศ steps เป็น Property ของ View เพื่อให้ TabView และ Button มองเห็น
    let steps = [
        OnboardingStep(
            title: "สแกนลิงก์ (URL)",
            description: "คัดลอกลิงก์ที่น่าสงสัยมาวางเพื่อตรวจสอบความเสี่ยงก่อนคลิก",
            icon: "link.circle.fill",
            color: Color(red: 0.12, green: 0.19, blue: 0.55)
        ),
        OnboardingStep(
            title: "สแกนเบอร์โทรศัพท์",
            description: "ตรวจสอบเบอร์โทรศัพท์มิจฉาชีพจากฐานข้อมูล  ของเรา",
            icon: "phone.circle.fill",
            color: .green
        ),
        OnboardingStep(
            title: "ตรวจสอบบัญชีธนาคาร",
            description: "เช็คเลขบัญชีหรือชื่อเจ้าของบัญชีก่อนโอนเงิน เพื่อความปลอดภัย",
            icon: "banknote.circle.fill",
            color: .orange
        ),
        OnboardingStep(
            title: "สแกนใบหน้า (Face Scan)",
            description: "ใช้ระบบ ตรวจสอบรูปภาพบุคคลว่ามีความเสี่ยงหรือไม่",
            icon: "person.crop.rectangle.stack.fill",
            color: .purple
        )
    ]

    var body: some View {
        VStack {
            // ปุ่มข้าม (Skip)
            HStack {
                Spacer()
                Button("ข้าม") {
                    hasSeenOnboarding = true
                    dismiss()
                }
                .foregroundStyle(.secondary)
                .padding()
            }

            // ส่วนแสดงเนื้อหาทีละ Step
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \.self) { index in
                    VStack(spacing: 25) {
                        Image(systemName: steps[index].icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(steps[index].color)
                        
                        Text(steps[index].title)
                            .font(.title2.bold())
                        
                        Text(steps[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .foregroundStyle(.secondary)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // ปุ่มนำทางด้านล่าง
            Button {
                if currentStep < steps.count - 1 {
                    withAnimation { currentStep += 1 }
                } else {
                    hasSeenOnboarding = true
                    dismiss()
                }
            } label: {
                Text(currentStep == steps.count - 1 ? "เริ่มใช้งานเลย" : "ถัดไป")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color(red: 0.12, green: 0.19, blue: 0.55)) // สีเดียวกับ UI หลัก
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview สำหรับตรวจสอบ UI
#Preview {
    UserGuideView()
}
