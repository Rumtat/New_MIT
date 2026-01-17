//
//  TitleBlock.swift
//  BYB_mit02
//

import SwiftUI

struct TitleBlock: View {
    let selectedType: ScanType

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title2).bold()

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
        }
        .padding(.top, 8)
    }

    private var title: String {
        switch selectedType {
        case .url: return "วางลิงค์เพื่อประเมินความเสี่ยง"
        case .qr: return "วางข้อมูล QR/Barcode เพื่อประเมินความเสี่ยง"
        case .phone: return "วางหมายเลขโทรศัพท์เพื่อประเมินความเสี่ยง"
        case .bank: return "วางชื่อหรือเลขบัญชีธนาคาร/พร้อมเพยเพื่อประเมินความเสี่ยง"
        case .sms, .text: return "วางข้อความ (SMS) เพื่อประเมินความเสี่ยง"
        case .report: return "แจ้งข่าวสารผู้โกงให้กับเรา"
        case .faceScan: return "สแกนรูป"
        }
    }

    private var subtitle: String {
        switch selectedType {
        case .url: return "ตรวจสอบลิงก์น่าสงสัยเพื่อประเมินความเสี่ยง"
        case .qr: return "ถ้าภายใน QR มีลิงก์ ระบบจะตรวจสอบความเสี่ยงให้"
        case .phone: return "ตรวจสอบเบอร์โทรศัพท์ที่น่าสงสัย"
        case .bank: return "ตรวจสอบบัญชีธนาคาร/พร้อมเพย์ที่น่าสงสัย"
        case .sms, .text: return "ระบบจะตรวจหา keywords และลิงก์ภายในข้อความ"
        case .report: return "แจ้งข้อมูลมิจฉาชีพเพื่อความปลอดภัยของสังคม"
        case .faceScan: return "สแกนรูป"
        }
    }
}
