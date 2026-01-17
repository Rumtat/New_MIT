//
//  ImageScanView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 14/1/2569 BE.
//

import SwiftUI
import PhotosUI

struct ImageScanView: View {
    @StateObject private var vm = ImageScannerViewModel()
    @StateObject private var history = HistoryStore()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            TitleBlock(selectedType: .faceScan)

            // ✅ ส่วนแสดงรูปภาพ (ถ้ามี URL จาก Firestore จะแสดงรูปนั้นทันที)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 250)
                
                if !vm.mockImageUrl.isEmpty {
                    // ดึงรูปจาก Imgur/เว็บนอก มาโชว์
                    AsyncImage(url: URL(string: vm.mockImageUrl)) { image in
                        image.resizable()
                             .scaledToFit()
                             .cornerRadius(15)
                             .padding(10)
                    } placeholder: {
                        ProgressView()
                    }
                } else if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(15)
                }
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("เลือกรูปเพื่อตรวจสอบ", systemImage: "photo.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .onChange(of: selectedItem) { newItem in
                if let item = newItem { handleImageSelection(item) }
            }

            // แสดงผลรายละเอียดสังเขป
            if !vm.resultName.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(vm.resultName).font(.headline)
                        Spacer()
                        StatusPill(level: vm.riskLevel)
                    }
                    Text(vm.infoSummary).font(.caption).foregroundColor(.secondary)
                    
                    Divider()
                    ForEach(vm.reasons, id: \.self) { r in
                        Text("• \(r)").font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 2)
            }
            Spacer()
        }
        .padding()
    }

    private func handleImageSelection(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.selectedImage = image
                // ✅ พอกดปุ่มปุ๊บ ให้ไปดึง Mock Data จาก Firestore มาโชว์เลย
                if let result = await vm.fetchMockData(documentID: "test_scammer_01") {
                    history.add(result)
                }
            }
        }
    }
}
