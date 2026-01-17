//
//  ThaiResultView.swift
//  BYB_mit02
//

import SwiftUI

struct ThaiResultView: View {
    let result: ScanResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(titleLine)
                    .font(.title2).bold()
                    .foregroundStyle(color)

                Text(labelLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                RecommendationCard(level: result.level)

                if result.type == .url || result.type == .qr, !isInvalidFormat {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ภาพตัวอย่างหน้าเว็บ").font(.headline)

                        let previewURL = "https://image.thum.io/get/width/600/crop/800/\(result.input.hasPrefix("http") ? result.input : "https://" + result.input)"

                        AsyncImage(url: URL(string: previewURL)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180).clipped().cornerRadius(12)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.1))
                                .frame(height: 180).overlay(ProgressView()).cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if !result.reasons.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(reasonHeader).font(.headline)
                        ForEach(result.reasons, id: \.self) { reason in
                            HStack(alignment: .top) {
                                Text("•").bold()
                                Text(reason).font(.body)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                }
            }
            .padding(16)
        }
        .navigationTitle("Result")
    }

    private var isInvalidFormat: Bool {
        result.reasons.contains("ไม่สามารถตรวจสอบได้เนื่องจากไม่พบที่อยู่ของเว็บไซต์")
    }

    private var color: Color {
        if isInvalidFormat { return .gray }
        switch result.level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var titleLine: String {
        if isInvalidFormat { return "ไม่สามารถตรวจสอบได้" }
        return result.level.displayTitle
    }

    private var reasonHeader: String {
        if isInvalidFormat { return "เหตุผล" }
        switch result.level {
        case .low: return "รายละเอียด"
        case .medium, .high: return "พบความเสี่ยงเนื่องจาก:"
        }
    }

    private var labelLine: String {
        switch result.type {
        case .sms, .text:
            return "ข้อความ: \(result.input)"
        case .qr:
            return "ข้อมูล QR: \(result.input)"
        default:
            return "ลิงก์: \(result.input)"
        }
    }
}

private struct RecommendationCard: View {
    let level: RiskLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("คำแนะนำ")
                .font(.headline)

            ForEach(recommendations, id: \.self) { line in
                HStack(alignment: .top) {
                    Text("•").bold()
                    Text(line)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }

    private var recommendations: [String] {
        switch level {
        case .low:
            return [
                "ตรวจสอบโดเมนและสะกดชื่อเว็บให้ถูกต้อง",
                "หลีกเลี่ยงการกรอกข้อมูลสำคัญ หากไม่มั่นใจ",
                "ถ้าได้รับจากแชท/ข้อความ ให้ถามผู้ส่งยืนยันอีกครั้ง"
            ]
        case .medium:
            return [
                "อย่ากรอกข้อมูลส่วนตัว/รหัสผ่าน/OTP",
                "ลองค้นชื่อโดเมนหรือชื่อเว็บเพิ่มก่อนทำรายการ",
                "หากเกี่ยวกับการเงิน แนะนำติดต่อหน่วยงาน/ธนาคารโดยตรง"
            ]
        case .high:
            return [
                "หยุดดำเนินการทันที และอย่ากดลิงก์ซ้ำ",
                "หากกรอกข้อมูลไปแล้ว ให้เปลี่ยนรหัสผ่านและแจ้งธนาคาร",
                "บันทึกหลักฐาน (สกรีนช็อต/ข้อความ) และทำรายงานในแอป"
            ]
        }
    }
}
