//
//  ReportScamView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 8/1/2569 BE.
//

import SwiftUI
import FirebaseFirestore

struct ReportScamView: View {
    @State private var type: ScanType = .phone
    @State private var input: String = ""
    @State private var selectedReason: String = "อื่นๆ (ระบุเอง)"
    @State private var customNote: String = ""
    
    // สำหรับ Account (Bank Report)
    @State private var fullName: String = ""
    @State private var accountNumber: String = ""
    @State private var bankName: String = ""
    
    @State private var isSending = false
    @State private var showSuccess = false

    private let db = Firestore.firestore()

    // รายการสาเหตุตามที่คุณระบุ
    let phoneReasons = [
        "แอบอ้างเป็นตำรวจ สภ.เมือง",
        "หลอกว่าพัวพันคดีฟอกเงินอ้างเป็นเจ้าหน้าที่ DHL",
        "แจ้งว่ามีพัสดุผิดกฎหมายตกค้าง",
        "หลอกให้ลงทุนเทรดทอง การันตีผลกำไรเกินจริง",
        "อ้างเป็นฝ่ายสินเชื่อธนาคารกสิกร หลอกถามเลข OTP",
        "เบอร์โทรขายประกันรบกวน โทรซ้ำบ่อยครั้ง",
        "อ้างเป็นเจ้าหน้าที่ กสทช. ขู่จะระงับเบอร์โทรศัพท์",
        "หลอกทำภารกิจกดไลก์สินค้า ชักชวนเข้ากลุ่มไลน์",
        "อื่นๆ (ระบุเอง)"
    ]

    var body: some View {
        VStack(spacing: 20) {
            TitleBlock(selectedType: .report)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // 1. เลือกประเภทการแจ้ง
                    Picker("ประเภท", selection: $type) {
                        Text("เบอร์โทร").tag(ScanType.phone)
                        Text("ลิงก์").tag(ScanType.url)
                        Text("บัญชี").tag(ScanType.bank)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _ in clearForm() }

                    // 2. ฟอร์มตามประเภทที่เลือก
                    if type == .phone {
                        phoneFields
                    } else if type == .url {
                        linkFields
                    } else if type == .bank {
                        bankFields
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }

            Button(action: sendReport) {
                if isSending {
                    ProgressView().tint(.white)
                } else {
                    Text("ส่งข้อมูลแจ้งรายงาน")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isFormValid ? Color.red : Color.gray)
            .cornerRadius(16)
            .disabled(!isFormValid || isSending)
        }
        .padding()
        // ✅ แก้ไข: เรียกใช้ ReportSuccessView โดยส่ง Binding 'isPresented' ให้ถูกต้อง
        .fullScreenCover(isPresented: $showSuccess) {
            ReportSuccessView(isPresented: $showSuccess)
        }
    }

    // MARK: - Sub Views
    
    private var phoneFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("เบอร์โทรศัพท์").font(.caption).foregroundStyle(.secondary)
            TextField("ระบุเบอร์โทร", text: $input)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)

            Text("สาเหตุที่พบ").font(.caption).foregroundStyle(.secondary)
            Picker("สาเหตุ", selection: $selectedReason) {
                ForEach(phoneReasons, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)

            if selectedReason == "อื่นๆ (ระบุเอง)" {
                TextField("โปรดระบุรายละเอียดเพิ่มเติม", text: $customNote)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var linkFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ลิงก์เว็บไซต์").font(.caption).foregroundStyle(.secondary)
            TextField("ระบุลิงก์", text: $input)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            Text("ระบุสิ่งที่พบในลิงก์ (เช่น หลอกว่าเป็น Flash)").font(.caption).foregroundStyle(.secondary)
            TextField("ระบุสาเหตุเล็กน้อย", text: $customNote)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var bankFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("เลขบัญชี").font(.caption).foregroundStyle(.secondary)
            TextField("ระบุเลขบัญชี (ถ้ามี)", text: $accountNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            Text("ชื่อ-นามสกุล").font(.caption).foregroundStyle(.secondary)
            TextField("ระบุชื่อ-นามสกุล (ถ้ามี)", text: $fullName)
                .textFieldStyle(.roundedBorder)

            Text("ธนาคาร").font(.caption).foregroundStyle(.secondary)
            TextField("ระบุชื่อธนาคาร", text: $bankName)
                .textFieldStyle(.roundedBorder)

            Text("รายละเอียดการโดนหลอก").font(.caption).foregroundStyle(.secondary)
            TextField("ระบุข้อมูล", text: $customNote)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Logic & DB
    
    private var isFormValid: Bool {
        switch type {
        case .phone, .url: return !input.isEmpty
        case .bank: return !fullName.isEmpty || !accountNumber.isEmpty
        default: return false
        }
    }

    private func sendReport() {
        isSending = true
        // ✅ แยก Collection ตามประเภทข้อมูล
        let collectionName = type == .phone ? "phone_report" : (type == .url ? "link_report" : "bank_report")
        
        var reportData: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending",
            "note": customNote
        ]

        if type == .phone {
            reportData["phoneNumber"] = input
            reportData["reason"] = selectedReason
        } else if type == .url {
            reportData["link"] = input
        } else if type == .bank {
            reportData["fullName"] = fullName
            reportData["accountNumber"] = accountNumber
            reportData["bankName"] = bankName
        }

        db.collection(collectionName).addDocument(data: reportData) { _ in
            isSending = false
            showSuccess = true // เปิดหน้าความสำเร็จ
            clearForm()
        }
    }

    private func clearForm() {
        input = ""; customNote = ""; fullName = ""; accountNumber = ""; bankName = ""; selectedReason = "อื่นๆ (ระบุเอง)"
    }
}
