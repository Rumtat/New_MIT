//
//  ImageScannerViewModel.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 14/1/2569 BE.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class ImageScannerViewModel: ObservableObject {
    @Published var resultName: String = ""
    @Published var isScanning: Bool = false
    @Published var infoSummary: String = ""
    @Published var reasons: [String] = []
    @Published var riskLevel: RiskLevel = .low
    @Published var mockImageUrl: String = "" // เก็บลิงก์รูปจากเว็บนอก
    
    private let db = Firestore.firestore()

    func fetchMockData(documentID: String) async -> ScanResult? {
        isScanning = true
        self.mockImageUrl = "" // รีเซ็ตค่ารูปเก่า
        
        do {
            // ✅ ดึงข้อมูลจาก Collection face_blacklist
            let docRef = db.collection("face_blacklist").document(documentID)
            let document = try await docRef.getDocument()
            
            if document.exists, let data = document.data() {
                // ดึงข้อความและรายละเอียด
                self.resultName = data["name"] as? String ?? "ตรวจพบความเสี่ยง"
                self.infoSummary = data["summary"] as? String ?? ""
                self.reasons = data["reasons"] as? [String] ?? []
                
                // ✅ ดึงลิงก์รูปภาพภายนอกที่เตรียมไว้
                self.mockImageUrl = data["imageUrl"] as? String ?? ""
                
                let rawLevel = data["riskLevel"] as? String ?? "low"
                self.riskLevel = rawLevel == "high" ? .high : (rawLevel == "medium" ? .medium : .low)
                
                self.isScanning = false
                return ScanResult(type: .faceScan, input: "External Mock ID: \(documentID)", level: self.riskLevel, reasons: self.reasons)
            }
        } catch {
            print("Firestore Error: \(error.localizedDescription)")
        }
        
        isScanning = false
        return nil
    }
}
