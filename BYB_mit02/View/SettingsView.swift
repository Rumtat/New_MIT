//
//  SettingsView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 8/1/2569 BE.
//

import SwiftUI

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    // ✅ เชื่อมต่อกับตัวแปรสถานะการเปิดแอปครั้งแรก
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @StateObject private var historyStore = HistoryStore()
    @State private var showDeleteAlert = false
    
    var body: some View {
        List {
            // ส่วนที่ 1: การจัดการข้อมูล
            Section(header: Text("การจัดการข้อมูล"), footer: Text("ประวัติการสแกนจะถูกเก็บไว้ภายในเครื่องเท่านั้น")) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .frame(width: 28, height: 28)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                        Text("ล้างประวัติการสแกนทั้งหมด")
                            .foregroundStyle(.red)
                    }
                }
            }
            
            // ส่วนที่ 2: การช่วยเหลือและทดสอบ (เพิ่มใหม่)
            Section("การช่วยเหลือ") {
                // ปุ่มดูคู่มือการใช้งาน
                NavigationLink(destination: UserGuideView()) {
                    SettingsRowCustom(
                        icon: "book.fill",
                        color: Color(red: 0.12, green: 0.19, blue: 0.55),
                        title: "คู่มือการใช้งาน"
                    )
                }
                
                // ✅ ปุ่มรีเซ็ตสถานะ (สำหรับ Developer/Tester)
                Button {
                    hasSeenOnboarding = false
                    // อาจจะเพิ่ม alert แจ้งเตือนว่ารีเซ็ตแล้ว
                } label: {
                    HStack {
                        SettingsRowCustom(
                            icon: "arrow.counterclockwise.circle.fill",
                            color: .gray,
                            title: "รีเซ็ตสถานะการใช้งานครั้งแรก"
                        )
                        Spacer()
                        if !hasSeenOnboarding {
                            Text("Reset แล้ว")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // ส่วนที่ 3: เกี่ยวกับแอป
            Section("เกี่ยวกับแอป") {
                NavigationLink(destination: AboutDetailView()) {
                    SettingsRowCustom(icon: "info.circle.fill", color: Color(red: 0.12, green: 0.19, blue: 0.55), title: "เกี่ยวกับ BYEMIT")
                }
                
                NavigationLink(destination: PrivacyDetailView()) {
                    SettingsRowCustom(icon: "lock.shield.fill", color: .green, title: "นโยบายความเป็นส่วนตัว")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("การตั้งค่า")
        .alert("ยืนยันการลบ", isPresented: $showDeleteAlert) {
            Button("ลบข้อมูล", role: .destructive) { historyStore.clear() }
            Button("ยกเลิก", role: .cancel) { }
        } message: {
            Text("ข้อมูลประวัติการสแกนทั้งหมดจะถูกลบออกจากเครื่องถาวร")
        }
    }
}

// MARK: - Helper UI Components
struct SettingsRowCustom: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)
            Text(title)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView()
    }
}

// MARK: - Subviews: รายละเอียด (อ้างอิงสไตล์ TitleBlock)
struct AboutDetailView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "shield.lefthalf.filled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color(red: 0.12, green: 0.19, blue: 0.55))
                    .padding(.top, 40)
                
                Text("BYEMIT")
                    .font(.title.bold())
                
                Text("แอปพลิเคชันสแกนความเสี่ยงสแกมเมอร์\nเพื่อความปลอดภัยของสังคมไทย")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundStyle(.secondary)
                
                Divider().padding()
                
                Text("เราใช้เทคโนโลยี Vision และฐานข้อมูล Firebase เพื่อตรวจสอบความเสี่ยงแบบ Real-time ให้คุณมั่นใจทุกการทำธุรกรรม")
                    .font(.subheadline)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("เกี่ยวกับ BYEMIT")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("นโยบายความเป็นส่วนตัว")
                    .font(.headline)
                Text("ข้อมูลที่คุณสแกน (เบอร์โทร, เลขบัญชี, ลิงก์) จะถูกส่งไปตรวจสอบกับฐานข้อมูลมิจฉาชีพเท่านั้น และจะไม่มีการเก็บข้อมูลระบุตัวตนของคุณไว้ในเซิร์ฟเวอร์")
                Text("ประวัติการใช้งานจะถูกบันทึกไว้ในหน่วยความจำของเครื่อง (Local Storage) ซึ่งคุณสามารถลบได้ด้วยตนเองผ่านเมนูตั้งค่า")
            }
            .padding()
        }
        .navigationTitle("ความเป็นส่วนตัว")
    }
}

// MARK: - PREVIEW สำหรับปรับแต่ง (Run เฉพาะหน้านี้ได้)
#Preview {
    NavigationStack {
        SettingsView()
    }
}
