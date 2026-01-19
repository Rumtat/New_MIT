//
//  BankScanView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 15/1/2569 BE.
//

import SwiftUI

struct BankScanView: View {
    // ✅ ชื่อใหม่ (ชัดกว่า)
    let onScanResult: (ScanResult) -> Void

    // ✅ คง initializer เดิมไว้ กัน call site พัง
    init(onResult: @escaping (ScanResult) -> Void) {
        self.onScanResult = onResult
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BankScanViewModel()
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
                            ownerNameInputSection

                            // ✅ ปุ่มลัดสำหรับทดสอบ
                            Button(action: { viewModel.fillSampleData() }) {
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

                if let err = viewModel.errorMessage {
                    Text(err).font(.caption).foregroundColor(.red)
                }

                startScanButton
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
            TextField("ป้อนตัวเลขเท่านั้น", text: $viewModel.accountNumberInput)
                .font(.title3)
                .keyboardType(.numberPad)
                .onChange(of: viewModel.accountNumberInput) { _, newValue in
                    viewModel.accountNumberInput = String(newValue.filter { $0.isNumber }.prefix(15))
                }
        }
    }

    private var ownerNameInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ชื่อและนามสกุลเจ้าของบัญชี")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("ป้อนชื่อ-นามสกุล (เช่น กาญจนา ทรัพย์แสน)", text: $viewModel.inputFullName)
                .font(.title3)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)

            Button(action: { viewModel.fillSampleData() }) {
                Text("ใช้ข้อมูลทดสอบ: กาญจนา ทรัพย์แสน")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
    }

    private var startScanButton: some View {
        Button {
            Task {
                if let result = await viewModel.scanBankAccount(mode: bankMode) {
                    onScanResult(result)
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
        .disabled(!canScan || viewModel.isLoading)
        .padding(.horizontal)
    }

    private var canScan: Bool {
        if bankMode == .byAccount {
            return !viewModel.accountNumberInput.isEmpty
        } else {
            return !viewModel.inputFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
