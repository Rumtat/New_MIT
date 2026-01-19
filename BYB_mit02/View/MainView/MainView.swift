//
//  MainView.swift
//  BYB_mit02
//

import SwiftUI
import PhotosUI
import UIKit

struct MainView: View {
    @StateObject private var viewModel = ScanViewModel()

    @State private var selectedResult: ScanResult?
    @State private var showSettings = false
    @State private var showLoadingOverlay = false
    @State private var selectedPhotoPickerItem: PhotosPickerItem? = nil

    // Sprint B
    @State private var showQRScannerSheet = false
    @State private var showHistoryScreen = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    HeaderBar(onSettings: { showSettings = true })
                        .background(Color.blue.ignoresSafeArea(edges: .top))

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            if viewModel.selectedType == .report {
                                ReportScamView()
                            } else if viewModel.selectedType == .faceScan {
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
                    selected: viewModel.selectedType,
                    onSelect: { newType in
                        viewModel.selectedType = newType
                        viewModel.errorMessage = nil
                    },
                    onReport: { viewModel.selectedType = .report }
                )
                .background(Color.blue.ignoresSafeArea(edges: .bottom))
            }
            .navigationBarHidden(true)

            // Result
            .navigationDestination(item: $selectedResult) { result in
                switch result.type {
                case .phone:
                    PhoneResultView(scanResult: result)
                case .bank:
                    BankResultView(result: result)
                default:
                    ThaiResultView(scanResult: result)
                }
            }

            // Settings
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }

            // History
            .navigationDestination(isPresented: $showHistoryScreen) {
                ScanHistoryView(historyStore: viewModel.historyStore) { r in
                    selectedResult = r
                }
            }

            .fullScreenCover(isPresented: $showLoadingOverlay) {
                InlineLoadingView()
            }

            // QR Scanner
            .sheet(isPresented: $showQRScannerSheet) {
                QRScannerView(
                    onScanned: { value in
                        showQRScannerSheet = false
                        handleScannedQRValue(value)
                    },
                    onClose: { showQRScannerSheet = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    private var mainScanContent: some View {
        VStack(spacing: 18) {
            TitleBlock(selectedType: viewModel.selectedType)

            InputCard(
                selectedType: viewModel.selectedType,
                inputText: $viewModel.inputText,
                phoneDigits: $viewModel.phoneDigits,
                fullName: $viewModel.fullNameInput,
                bankMode: $viewModel.bankMode,
                selectedPhotoItem: $selectedPhotoPickerItem,
                onPickPhotoChanged: { },
                onPaste: pasteFromClipboard,
                onImportFile: { }
            )

            // ปุ่มเปิดกล้อง QR เฉพาะโหมด QR
            if viewModel.selectedType == .qr {
                Button {
                    showQRScannerSheet = true
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

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }

            scanButton

            // ✅ เหลือ Recent แค่ “ชุดเดียว”
            recentHeader

            if !viewModel.historyStore.items.isEmpty {
                RecentSection(
                    items: Array(viewModel.historyStore.items.prefix(3)),   // ✅ แสดงแค่ 3 อันล่าสุด (กันรก)
                    onClear: { viewModel.historyStore.clear() },
                    onTap: { r in selectedResult = r }
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private var recentHeader: some View {
        HStack {
            Text("ผลสแกนย้อนหลัง")
                .font(.title3).bold()

            Spacer()

            Button {
                showHistoryScreen = true
            } label: {
                Text("ดูประวัติทั้งหมด")
                    .font(.subheadline).bold()
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.blue)
            .disabled(viewModel.historyStore.items.isEmpty)
            .opacity(viewModel.historyStore.items.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var scanButton: some View {
        Button {
            Task { await performScan() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .bold))
                Text(scanButtonTitleText(for: viewModel.selectedType))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(viewModel.normalizedInputForScan().isEmpty ? Color.gray.opacity(0.3) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .disabled(viewModel.isLoading || viewModel.normalizedInputForScan().isEmpty)
    }

    private func handleScannedQRValue(_ rawValue: String) {
        viewModel.errorMessage = nil

        // ✅ ถ้า QR เป็น URL -> normalize แล้วตรวจเหมือนลิงก์
        if viewModel.looksLikeUrl(rawValue) {
            viewModel.selectedType = .url
            viewModel.inputText = viewModel.normalizeUrlInput(rawValue)
        } else {
            viewModel.selectedType = .qr
            viewModel.inputText = rawValue
        }

        Task { await performScan() }
    }

    private func performScan() async {
        showLoadingOverlay = true

        let result: ScanResult?

        switch viewModel.selectedType {
        case .phone:
            result = await viewModel.runPhoneScan()
        case .bank:
            result = await viewModel.runBankScan()
        case .url, .qr, .sms, .text:
            result = await viewModel.runScan()
        case .faceScan, .report:
            result = nil
        }

        showLoadingOverlay = false

        if let r = result {
            selectedResult = r
            viewModel.clearAllInputs()
        }
    }

    private func scanButtonTitleText(for type: ScanType) -> String {
        switch type {
        case .url: return "สแกนลิงค์ที่ต้องสงสัย"
        case .qr: return "สแกนคิวอาร์โค้ดที่ต้องสงสัย"
        case .sms: return "สแกนข้อความที่ต้องสงสัย"
        case .phone: return "สแกนเบอร์โทรศัพท์ที่ต้องสงสัย"
        case .bank: return "สแกนเลขบัญชีหรือชื่อที่ต้องสงสัย"
        case .text: return "SCAN TEXT"
        case .faceScan: return "SCAN IMAGE"
        case .report: return "REPORT"
        }
    }

    private func pasteFromClipboard() {
        guard let s = UIPasteboard.general.string else { return }
        viewModel.errorMessage = nil

        switch viewModel.selectedType {
        case .phone:
            viewModel.phoneDigits = String(s.filter { "0123456789+".contains($0) }.prefix(15))

        case .bank:
            if viewModel.bankMode == .byAccount {
                viewModel.inputText = String(s.filter { $0.isNumber }.prefix(32))
            } else {
                viewModel.fullNameInput = s
            }

        case .url:
            viewModel.inputText = viewModel.normalizeUrlInput(s)

        default:
            viewModel.inputText = s
        }
    }
}
