//
//  BankResultView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//


import SwiftUI

struct BankResultView: View {
    let result: ScanResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. ส่วนแสดงสถานะความเสี่ยงหลัก
                statusHeaderSection

                // 2. รายละเอียดบัญชีที่ตรวจสอบ
                VStack(spacing: 0) {
                    detailRow(title: "เลขบัญชี/พร้อมเพย์", value: result.input)
                    
                    if let bank = result.bankName {
                        Divider().padding(.vertical, 10)
                        detailRow(title: "ธนาคาร", value: bank)
                    }
                    
                    if let owner = result.ownerName {
                        Divider().padding(.vertical, 10)
                        detailRow(title: "ชื่อเจ้าของบัญชี", value: owner)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                .padding(.horizontal)

                // 3. รายละเอียดเหตุผลจากการตรวจสอบ (ดึงข้อมูลจาก Array ใน Firestore)
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                        Text("รายละเอียดการตรวจสอบ")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                    if result.reasons.isEmpty || result.level == .low {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("ไม่พบประวัติการทุจริตในฐานข้อมูลปัจจุบัน")
                                .font(.subheadline)
                        }
                    } else {
                        ForEach(result.reasons, id: \.self) { reason in
                            HStack(alignment: .top, spacing: 10) {
                                Text("•")
                                    .bold()
                                    .foregroundColor(statusColor)
                                Text(reason)
                                    .font(.subheadline)
                                    .lineSpacing(4)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                .padding(.horizontal)

                // 4. คำแนะนำเพิ่มเติมตามระดับความเสี่ยง
                adviceSection
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("ผลการตรวจสอบ")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helper Views

    private var statusHeaderSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(statusColor)
            }
            
            VStack(spacing: 4) {
                Text(result.level.displayTitle)
                    .font(.title2.bold())
                    .foregroundColor(statusColor)
                
                Text(statusSubTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }

    private var adviceSection: some View {
        VStack {
            if result.level != .low {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.title2)
                    Text("คำเตือน: โปรดระมัดระวังเป็นพิเศษก่อนดำเนินการโอนเงินไปยังบัญชีนี้ หากไม่แน่ใจควรตรวจสอบผ่านช่องทางหลักของธนาคารอีกครั้ง")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(statusColor.opacity(0.1))
                .foregroundColor(statusColor)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch result.level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var statusIcon: String {
        switch result.level {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "shield.exclamationmark.fill"
        }
    }

    private var statusSubTitle: String {
        switch result.level {
        case .low: return "ตรวจสอบแล้ว ไม่พบความเสี่ยง"
        case .medium: return "พบข้อมูลบางส่วนที่ควรระวัง"
        case .high: return "พบข้อมูลการทุจริตในฐานข้อมูล"
        }
    }
}
