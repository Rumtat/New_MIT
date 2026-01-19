//
//  ImageScanView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 14/1/2569 BE.
//

import SwiftUI
import PhotosUI

struct ImageScanView: View {

    @StateObject private var viewModel = ImageScanViewModel()
    @StateObject private var historyStore = ScanHistoryStore.shared

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            TitleBlock(selectedType: .faceScan)

            // MARK: - Image Preview
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 250)

                if !viewModel.previewImageURL.isEmpty {
                    AsyncImage(url: URL(string: viewModel.previewImageURL)) { image in
                        image
                            .resizable()
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

            // MARK: - Picker
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("เลือกรูปเพื่อตรวจสอบ", systemImage: "photo.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .onChange(of: selectedItem) { newItem in
                if let item = newItem {
                    handleSelectedImage(item)
                }
            }

            // MARK: - Result
            if !viewModel.resultTitle.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(viewModel.resultTitle)
                            .font(.headline)

                        Spacer()

                        StatusPill(riskLevel: viewModel.riskLevel)
                    }

                    Text(viewModel.summaryText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    ForEach(viewModel.reasons, id: \.self) { r in
                        Text("• \(r)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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

    // MARK: - Helpers

    private func handleSelectedImage(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {

                selectedImage = image

                if let result = await viewModel.scanMockFace(documentID: "test_scammer_01") {
                    historyStore.add(result)
                }
            }
        }
    }
}
