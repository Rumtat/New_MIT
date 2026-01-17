//
//  BankScanView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//
import SwiftUI

struct BankScanView: View {
    let onResult: (ScanResult) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = BankScanViewModel()
    @State private var bankMode: BankSearchMode = .byAccount

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // เลือกโหมดการค้นหา
                Picker("Mode", selection: $bankMode) {
                    Text("เลขบัญชี").tag(BankSearchMode.byAccount)
                    Text("ชื่อ-นามสกุล").tag(BankSearchMode.byName)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(spacing: 20) {
                    if bankMode == .byAccount {
                        accountInputSection
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            nameInputSection
                            
                            // ✅ ปุ่มลัดสำหรับทดสอบ
                            Button(action: { vm.fillTestData() }) {
                                HStack {
                                    Image(systemName: "testtube.2")
                                    Text("ใช้ข้อมูลทดสอบ (กาญจนา ทรัพย์แสน)")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                if let err = vm.errorMessage {
                    Text(err).font(.caption).foregroundColor(.red)
                }

                scanButton
                Spacer()
            }
            .navigationTitle("สแกนบัญชี")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ปิด") { dismiss() }
                }
            }
        }
    }

    private var accountInputSection: some View {
        VStack(alignment: .leading) {
            Text("เลขบัญชี / พร้อมเพย์").font(.caption).foregroundColor(.secondary)
            TextField("ป้อนตัวเลขเท่านั้น", text: $vm.inputText)
                .font(.title3)
                .keyboardType(.numberPad)
                .onChange(of: vm.inputText) { oldValue, newValue in
                    vm.inputText = String(newValue.filter { $0.isNumber }.prefix(15))
                }
        }
    }

    // เปลี่ยนส่วน nameInputSection ใน BankScanView.swift
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ชื่อและนามสกุลเจ้าของบัญชี")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // ✅ ใช้ตัวแปร inputFullName เพียงตัวเดียว
            TextField("ป้อนชื่อ-นามสกุล (เช่น กาญจนา ทรัพย์แสน)", text: $vm.inputFullName)
                .font(.title3)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
            
            // ปุ่มลัดสำหรับทดสอบเพื่อให้มั่นใจว่าดึงข้อมูลได้
            Button(action: { vm.fillTestData() }) {
                Text("ใช้ข้อมูลทดสอบ: กาญจนา ทรัพย์แสน")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
    }


    private var scanButton: some View {
        Button {
            Task {
                if let result = await vm.scanAccount(mode: bankMode) {
                    onResult(result)
                    dismiss()
                }
            }
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("เริ่มการตรวจสอบ")
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(canScan ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(!canScan || vm.isLoading)
        .padding(.horizontal)
    }

    private var canScan: Bool {
        if bankMode == .byAccount {
            return !vm.inputText.isEmpty
        } else {
            return !vm.inputFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

}
