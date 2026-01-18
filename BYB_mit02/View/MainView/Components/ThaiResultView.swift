//
//  ThaiResultView.swift
//  BYB_mit02
//

import SwiftUI

struct ThaiResultView: View {
    let result: ScanResult

    private var isUnknown: Bool {
        result.reasons.contains("ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์")
    }

    private var isNoData: Bool {
        result.reasons.contains(RiskService.noDataReason)
    }

    private var accent: Color {
        if isUnknown { return .gray }
        if isNoData { return .gray }
        switch result.level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var headline: String {
        if isUnknown { return "ไม่สามารถตรวจสอบได้" }
        if isNoData { return "ไม่มีข้อมูลในระบบ" }
        switch result.level {
        case .low: return "ปลอดภัย"
        case .medium: return "มีความเสี่ยง"
        case .high: return "ไม่ปลอดภัย"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                VStack(spacing: 10) {
                    Image(systemName: isNoData || isUnknown ? "questionmark.circle.fill" : (result.level == .high ? "xmark.octagon.fill" : (result.level == .medium ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")))
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(accent)

                    Text(headline)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(result.input)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 18)

                // แสดงเหตุผล (รวม heuristic)
                VStack(alignment: .leading, spacing: 10) {
                    Text("รายละเอียดการประเมิน")
                        .font(.headline)

                    if result.reasons.isEmpty {
                        Text("ไม่มีรายละเอียด")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(result.reasons.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(accent.opacity(0.8))
                                    .padding(.top, 6)

                                Text(result.reasons[i])
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 16)

                // คำแนะนำ
                VStack(alignment: .leading, spacing: 10) {
                    Text("คำแนะนำ")
                        .font(.headline)

                    Text(adviceText())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
        }
        .navigationTitle("ผลการตรวจสอบ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func adviceText() -> String {
        if isNoData {
            return "ระบบยังไม่มีข้อมูลรายการนี้ในฐานข้อมูล แนะนำตรวจสอบเพิ่มเติมจากแหล่งทางการ และอย่ากรอกข้อมูลส่วนตัวหากไม่มั่นใจ"
        }
        if isUnknown {
            return "ไม่สามารถตรวจสอบได้ในขณะนี้ ลองตรวจสอบใหม่อีกครั้ง หรือเช็กการเชื่อมต่ออินเทอร์เน็ต"
        }
        switch result.level {
        case .low:
            return "ยังไม่พบความเสี่ยงเด่นชัด แต่ควรตรวจสอบผู้ส่ง/แหล่งที่มาให้แน่ใจก่อนดำเนินการ"
        case .medium:
            return "พบปัจจัยเสี่ยงบางอย่าง ควรหลีกเลี่ยงการกรอกข้อมูลส่วนตัว/OTP และตรวจสอบกับแหล่งทางการ"
        case .high:
            return "มีความเสี่ยงสูง แนะนำหยุดดำเนินการทันที ไม่กรอกข้อมูล/ไม่โอนเงิน และรายงานหากพบความผิดปกติ"
        }
    }
}
