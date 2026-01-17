//
//  MainView.swift
//  BYB_mit02
//

import SwiftUI
import PhotosUI
import UIKit

struct MainView: View {
    @StateObject private var vm = ScanViewModel()

    @State private var goResult: ScanResult?
    @State private var navigateToSettings = false
    @State private var showLoading = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // Sprint B
    @State private var showQRScanner = false
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    HeaderBar(onSettings: { navigateToSettings = true })
                        .background(Color.blue.ignoresSafeArea(edges: .top))

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            if vm.selectedType == .report {
                                ReportScamView()
                            } else if vm.selectedType == .faceScan {
                                ImageScanView()
                            } else {
                                mainScanContent
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 150)
                    }
                }

                BottomActionBar(
                    selected: vm.selectedType,
                    onSelect: { newType in
                        vm.selectedType = newType
                        vm.errorMessage = nil
                    },
                    onReport: { vm.selectedType = .report }
                )
                .background(Color.blue.ignoresSafeArea(edges: .bottom))
            }
            .navigationBarHidden(true)

            // Result
            .navigationDestination(item: $goResult) { result in
                switch result.type {
                case .phone:
                    PhoneResultView(result: result)
                case .bank:
                    BankResultView(result: result)
                default:
                    ThaiResultView(result: result)
                }
            }

            // Settings
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }

            // History
            .navigationDestination(isPresented: $showHistory) {
                HistoryView(history: vm.history) { r in
                    goResult = r
                }
            }

            .fullScreenCover(isPresented: $showLoading) {
                InlineLoadingView()
            }

            // QR Scanner
            .sheet(isPresented: $showQRScanner) {
                QRScannerView(
                    onResult: { value in
                        showQRScanner = false
                        handleQRScan(value)
                    },
                    onCancel: { showQRScanner = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    private var mainScanContent: some View {
        VStack(spacing: 18) {
            TitleBlock(selectedType: vm.selectedType)

            InputCard(
                selectedType: vm.selectedType,
                inputText: $vm.inputText,
                phoneDigits: $vm.phoneDigits,
                fullName: $vm.fullNameInput,
                bankMode: $vm.bankMode,
                selectedPhotoItem: $selectedPhotoItem,
                onPickPhotoChanged: { },
                onPaste: pasteFromClipboard,
                onImportFile: { }
            )

            // ปุ่มเปิดกล้อง QR เฉพาะโหมด QR
            if vm.selectedType == .qr {
                Button {
                    showQRScanner = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 18, weight: .bold))
                        Text("SCAN QR (Camera)")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 16)
            }

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }

            scanButton

            // ✅ เหลือ Recent แค่ “ชุดเดียว”
            recentHeader

            if !vm.history.items.isEmpty {
                RecentSection(
                    items: Array(vm.history.items.prefix(3)),   // ✅ แสดงแค่ 3 อันล่าสุด (กันรก)
                    onClear: { vm.history.clear() },
                    onTap: { r in goResult = r }
                )
            }
        }
        .padding(.horizontal, 16)
    }


    private var recentHeader: some View {
        HStack {
            Text("Recent Scan")
                .font(.title3).bold()

            Spacer()

            Button {
                showHistory = true
            } label: {
                Text("ดูประวัติทั้งหมด")
                    .font(.subheadline).bold()
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.blue)
            .disabled(vm.history.items.isEmpty)
            .opacity(vm.history.items.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var scanButton: some View {
        Button {
            Task { await runScan() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .bold))
                Text(scanButtonTitle(for: vm.selectedType))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(vm.normalizedInputForScan().isEmpty ? Color.gray.opacity(0.3) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .disabled(vm.isLoading || vm.normalizedInputForScan().isEmpty)
    }

    private func handleQRScan(_ rawValue: String) {
        vm.errorMessage = nil

        // ✅ ถ้า QR เป็น URL -> normalize แล้วตรวจเหมือนลิงก์
        if vm.looksLikeUrl(rawValue) {
            vm.selectedType = .url
            vm.inputText = vm.normalizeUrlInput(rawValue)
        } else {
            // ไม่ใช่ URL ก็ตรวจแบบ QR data ปกติ (ใน Sprint A scan logic จะ treat qr เหมือน url ใน RiskService อยู่แล้ว)
            vm.selectedType = .qr
            vm.inputText = rawValue
        }

        Task { await runScan() }
    }

    private func runScan() async {
        showLoading = true

        let res: ScanResult?

        switch vm.selectedType {
        case .phone:
            res = await vm.runPhoneScan()
        case .bank:
            res = await vm.runBankScan()
        case .url, .qr, .sms, .text:
            res = await vm.runScan()
        case .faceScan, .report:
            res = nil
        }

        showLoading = false

        if let r = res {
            goResult = r

            // ✅ กดค้นหาแล้วล้างข้อความทันที
            vm.clearAllInputs()
        }
    }

    private func scanButtonTitle(for type: ScanType) -> String {
        switch type {
        case .url: return "SCAN LINK"
        case .qr: return "SCAN QR DATA"
        case .sms: return "SCAN SMS"
        case .phone: return "SCAN PHONE"
        case .bank: return "SCAN ACCOUNT"
        case .text: return "SCAN TEXT"
        case .faceScan: return "SCAN IMAGE"
        case .report: return "REPORT"
        }
    }

    private func pasteFromClipboard() {
        guard let s = UIPasteboard.general.string else { return }
        vm.errorMessage = nil

        switch vm.selectedType {
        case .phone:
            vm.phoneDigits = String(s.filter { "0123456789+".contains($0) }.prefix(15))

        case .bank:
            if vm.bankMode == .byAccount {
                vm.inputText = String(s.filter { $0.isNumber }.prefix(32))
            } else {
                vm.fullNameInput = s
            }

        case .url:
            vm.inputText = vm.normalizeUrlInput(s)

        default:
            vm.inputText = s
        }
    }
}
