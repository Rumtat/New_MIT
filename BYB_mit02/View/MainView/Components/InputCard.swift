//
//  InputCard.swift
//  BYB_mit02
//

import SwiftUI
import PhotosUI

struct InputCard: View {
    let selectedType: ScanType
    @Binding var inputText: String
    @Binding var phoneDigits: String
    @Binding var fullName: String
    @Binding var bankMode: BankSearchMode
    @Binding var selectedPhotoItem: PhotosPickerItem?

    let onPickPhotoChanged: () -> Void
    let onPaste: () -> Void
    let onImportFile: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.25), lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))

                content
                    .padding(14)

                Button(action: onPaste) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.title3)
                        .padding(12)
                }
            }
            .frame(height: fieldHeight)
            .padding(.horizontal, 16)
        }
    }

    private var fieldHeight: CGFloat {
        switch selectedType {
        case .bank: return 140
        case .phone: return 86
        case .url, .qr, .sms, .text: return 140
        case .report, .faceScan: return 0
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedType {
        case .phone:
            VStack(alignment: .leading, spacing: 10) {
                Text("Phone Number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("ระบุเบอร์โทรศัพท์ หรือ +รหัสประเทศ", text: $phoneDigits)
                    .keyboardType(.phonePad)
                    .font(.title2)
                    .onChange(of: phoneDigits) { _, newValue in
                        let allowed = "0123456789+"
                        let filtered = newValue.filter { allowed.contains($0) }
                        phoneDigits = String(filtered.prefix(15))
                    }
            }

        case .bank:
            VStack(alignment: .leading, spacing: 8) {
                Text("Account / Name Search")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Search Mode", selection: $bankMode) {
                    Text("By Account").tag(BankSearchMode.byAccount)
                    Text("By Name").tag(BankSearchMode.byName)
                }
                .pickerStyle(.segmented)

                if bankMode == .byName {
                    TextField("ป้อนชื่อ-นามสกุลเจ้าของบัญชี", text: $fullName)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                } else {
                    TextField("เลขบัญชี / PromptPay", text: $inputText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
            }

        case .url, .qr:
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedType == .qr ? "QR/Barcode Data" : "Link (English only)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $inputText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: inputText) { _, newValue in
                        let filtered = newValue.filter { $0.asciiValue.map { $0 >= 32 && $0 <= 126 } ?? false }
                        if filtered != newValue { inputText = filtered }
                    }
            }

        case .sms, .text:
            VStack(alignment: .leading, spacing: 10) {
                Text("SMS / Message")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $inputText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

        case .report, .faceScan:
            EmptyView()
        }
    }
}
