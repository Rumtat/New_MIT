//
//  ImageScanViewModel.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 14/1/2569 BE.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class ImageScanViewModel: ObservableObject {

    // MARK: - UI State
    @Published var resultTitle: String = ""
    @Published var summaryText: String = ""
    @Published var reasons: [String] = []
    @Published var riskLevel: RiskLevel = .low
    @Published var previewImageURL: String = ""
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()

    // MARK: - Scan

    /// Scan mock face data from Firestore (temporary)
    func scanMockFace(documentID: String) async -> ScanResult? {
        isLoading = true
        previewImageURL = ""

        defer { isLoading = false }

        do {
            let docRef = db.collection("face_blacklist").document(documentID)
            let document = try await docRef.getDocument()

            guard document.exists, let data = document.data() else { return nil }

            resultTitle = data["name"] as? String ?? "ตรวจพบความเสี่ยง"
            summaryText = data["summary"] as? String ?? ""
            reasons = data["reasons"] as? [String] ?? []
            previewImageURL = data["imageUrl"] as? String ?? ""

            let rawLevel = data["riskLevel"] as? String ?? "low"
            riskLevel =
                rawLevel == "high" ? .high :
                rawLevel == "medium" ? .medium : .low

            return ScanResult(
                type: .faceScan,
                input: "External Mock ID: \(documentID)",
                riskLevel: riskLevel,
                reasons: reasons
            )
        } catch {
            print("❌ Firestore Error:", error.localizedDescription)
            return nil
        }
    }
}
