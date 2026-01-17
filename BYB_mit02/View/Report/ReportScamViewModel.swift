//
//  ReportScamViewModel.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 11/1/2569 BE.
//

import Foundation

@MainActor
final class ReportScamViewModel: ObservableObject {
    private let service: ReportScamServicing

    // ฉีด Service เข้ามาตามโครงสร้างที่วางไว้
    init(service: ReportScamServicing = ReportScamService()) {
        self.service = service
    }

    func submit(_ report: ReportCase) async throws {
        // เรียกใช้ Service เพื่อส่งข้อมูล
        try await service.submit(report)
        print("Report submitted successfully")
    }
}
