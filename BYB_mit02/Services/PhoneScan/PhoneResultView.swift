//
//  PhoneResultView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 13/1/2569 BE.
//

import SwiftUI

struct PhoneResultView: View {
    let result: ScanResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header สถานะ
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: result.level == .low ? "shield.check.fill" : "phone.down.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(statusColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text(result.level.displayTitle)
                            .font(.title.bold())
                            .foregroundColor(statusColor)
                        
                        Text(result.input)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)

                // ✅ เพิ่มส่วน: ข้อมูลเชิงลึก (Insights)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                        Text("ข้อมูลเชิงลึก").font(.headline)
                    }
                    .foregroundColor(.blue)

                    Divider()

                    // แสดงรายการข้อมูลถิ่นกำเนิด เครือข่าย และประเภท
                    let infoList = result.reasons.filter { $0.contains(":") }
                    ForEach(infoList, id: \.self) { info in
                        Text("• \(info)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)

                // รายละเอียดความเสี่ยง
                VStack(alignment: .leading, spacing: 15) {
                    Text("ผลการวิเคราะห์ความเสี่ยง")
                        .font(.headline)
                    
                    let riskList = result.reasons.filter { !$0.contains(":") }
                    if riskList.isEmpty && result.level == .low {
                        Text("• ไม่พบข้อมูลในฐานข้อมูลมิจฉาชีพ")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(riskList, id: \.self) { reason in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(statusColor)
                                Text(reason).font(.body)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal)

                // คำแนะนำ
                if result.level != .low {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ข้อแนะนำสำหรับคุณ:").font(.headline).foregroundColor(.red)
                        Text("• อย่ากดลิงก์ที่ส่งมาจากเบอร์นี้\n• อย่าให้ข้อมูลส่วนตัวหรือโอนเงิน\n• บล็อกเบอร์นี้ทันทีผ่านระบบมือถือ")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                Spacer()
            }
        }
        .navigationTitle("ผลการสแกนเบอร์")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusColor: Color {
        switch result.level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
