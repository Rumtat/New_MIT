//
//  OnboardingStep.swift
//  BYB_mit02
//

import SwiftUI
import UIKit



// MARK: - Main View

struct UserGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentStep = 0

    private let steps: [OnboardingStep] = [
        .init(title: "แอปนี้ช่วยอะไรคุณ?",
              detail: "BYEMIT เปลี่ยนเครื่องมือช่วยตรวจสอบความเสี่ยงก่อนคลิก",
              imageName: "onboard_1"),
        .init(title: "เลือกรูปแบบการสแกน",
              detail: "เลือกการสแกนที่ต้องการจากปุ่มด้านล่าง",
              imageName: "onboard_2"),
        .init(title: "ใส่ข้อมูลที่ต้องการตรวจสอบ",
              detail: "วางข้อมูลหรือเลือกวิธีที่สะดวก!",
              imageName: "onboard_3"),
        .init(title: "กด Scan เพื่อดูผลลัพธ์",
              detail: "เมื่อใส่ข้อมูลแล้ว กด Scan ได้เลย ระบบจะแจ้งผลทันที",
              imageName: "onboard_4"),
        .init(title: "ดูประวัติการสแกน",
              detail: "หลังการสแกนคุณสามารถดูผลการสแกนล่าสุดได้ตลอดเวลา",
              imageName: "onboard_5"),
        .init(title: "รายงานข้อมูลน่าสงสัย",
              detail: "ช่วยกันป้องกัน Scam ให้ทุกคน",
              imageName: "onboard_6",
              primaryButtonTitle: "REPORT SCAM"),
        .init(title: "เริ่มใช้งานเลย!",
              detail: "",
              imageName: "onboard_7",
              primaryButtonTitle: "เริ่มเลย")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("ข้าม") { finish() }
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

            Button {
                currentStep < steps.count - 1
                ? withAnimation { currentStep += 1 }
                : finish()
            } label: {
                Text(buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color(red: 0.12, green: 0.19, blue: 0.55))
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)
        }
    }

    private var buttonTitle: String {
        steps[currentStep].primaryButtonTitle
        ?? (currentStep == steps.count - 1 ? "เริ่มเลย" : "ถัดไป")
    }

    private func finish() {
        hasSeenOnboarding = true
        dismiss()
    }
}

// MARK: - Page

private struct OnboardingPage: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            AssetImage(name: step.imageName)
                .padding(.horizontal, 22)

            VStack(spacing: 10) {
                Text(step.title)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)

                if !step.detail.isEmpty {
                    Text(step.detail)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Asset helper

private struct AssetImage: View {
    let name: String

    var body: some View {
        if let ui = UIImage(named: name) {
            Image(uiImage: ui).resizable().scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .overlay(Text("รอใส่รูป"))
                .frame(height: 320)
        }
    }
}
