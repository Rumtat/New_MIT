//
//  OnboardingStep.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//

//
//  OnboardingStep.swift
//  BYB_mit02
//
//  Onboarding แบบใช้ “รูปภาพจริง” จาก Assets
//

import SwiftUI
import UIKit

// MARK: - Model

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String

    /// ชื่อรูปใน Assets.xcassets (คุณเอารูปมาใส่เอง)
    let imageName: String

    /// (Optional) ถ้าอยากมีปุ่มด้านล่างบางหน้าชื่อพิเศษ
    var primaryButtonTitle: String? = nil
}

// MARK: - Main View

struct UserGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    @State private var currentStep = 0

    // ✅ เปลี่ยนชื่อ imageName ให้ตรงกับรูปที่คุณจะใส่ใน Assets
    private let steps: [OnboardingStep] = [
        .init(
            title: "แอปนี้ช่วยอะไรคุณ?",
            description: "BYEMIT เปลี่ยนเครื่องมือช่วยตรวจสอบความเสี่ยงก่อนคลิก",
            imageName: "onboard_1"
        ),
        .init(
            title: "เลือกรูปแบบการสแกน",
            description: "เลือกการสแกนที่ต้องการจากปุ่มด้านล่าง",
            imageName: "onboard_2"
        ),
        .init(
            title: "ใส่ข้อมูลที่ต้องการตรวจสอบ",
            description: "วางข้อมูลหรือเลือกวิธีที่สะดวก!",
            imageName: "onboard_3"
        ),
        .init(
            title: "กด Scan เพื่อดูผลลัพธ์",
            description: "เมื่อใส่ข้อมูลแล้ว กด Scan ได้เลย ระบบจะแจ้งผลทันที",
            imageName: "onboard_4"
        ),
        .init(
            title: "ดูประวัติการสแกน",
            description: "หลังการสแกนคุณสามารถดูผลการสแกนล่าสุดได้ตลอดเวลา",
            imageName: "onboard_5"
        ),
        .init(
            title: "รายงานข้อมูลน่าสงสัย",
            description: "ช่วยกันป้องกัน Scam ให้ทุกคน",
            imageName: "onboard_6",
            primaryButtonTitle: "REPORT SCAM"
        ),
        .init(
            title: "เริ่มใช้งานเลย!",
            description: "",
            imageName: "onboard_7",
            primaryButtonTitle: "เริ่มเลย"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Top bar (ปุ่มข้าม)
            HStack {
                Spacer()
                Button("ข้าม") {
                    finish()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            TabView(selection: $currentStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    OnboardingPage(step: step)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom primary button
            Button {
                if currentStep < steps.count - 1 {
                    withAnimation(.easeInOut) { currentStep += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color(red: 0.12, green: 0.19, blue: 0.55))
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
    }

    private var buttonTitle: String {
        // ถ้าหน้ามีปุ่มเฉพาะ ให้ใช้ชื่อนั้น
        if let custom = steps[currentStep].primaryButtonTitle {
            // หน้าสุดท้ายให้ปิด onboarding
            if currentStep == steps.count - 1 { return custom }
            // หน้าอื่น ๆ (ถ้ามี) ใช้เป็นปุ่ม (แต่ยังเลื่อนไปหน้าถัดไป)
            return custom
        }
        return (currentStep == steps.count - 1) ? "เริ่มเลย" : "ถัดไป"
    }

    private func finish() {
        hasSeenOnboarding = true
        dismiss()
    }
}

// MARK: - Page UI

private struct OnboardingPage: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 18)

            // รูปหลัก (จาก Assets) — ถ้าไม่เจอรูป จะแสดง placeholder ให้รู้ว่าต้องใส่รูป
            AssetImage(name: step.imageName)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)

            VStack(spacing: 10) {
                Text(step.title)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)

                if !step.description.isEmpty {
                    Text(step.description)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }

            Spacer(minLength: 22)
        }
    }
}

// MARK: - Asset image helper (มี placeholder)

private struct AssetImage: View {
    let name: String

    var body: some View {
        Group {
            if let ui = UIImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
            } else {
                // Placeholder: คุณจะเห็นกรอบนี้ถ้ายังไม่ได้ใส่รูป/ชื่อไม่ตรง
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .foregroundStyle(.gray.opacity(0.35))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.gray.opacity(0.6))
                            Text("รอใส่รูป")
                                .font(.caption)
                                .foregroundStyle(.gray.opacity(0.8))
                            Text(name)
                                .font(.caption2).bold()
                                .foregroundStyle(.gray.opacity(0.9))
                        }
                        .padding(16)
                    )
                    .frame(height: 320)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UserGuideView()
}

