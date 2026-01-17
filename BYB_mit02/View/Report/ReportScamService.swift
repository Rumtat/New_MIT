//
//  ReportScamService.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 11/1/2569 BE.
//

import Foundation

// 1. กำหนด Protocol เพื่อให้ง่ายต่อการทำ Unit Test ในอนาคต
protocol ReportScamServicing {
    func submit(_ report: ReportCase) async throws
}

// 2. สร้าง Class หลักที่ทำงานจริง
final class ReportScamService: ReportScamServicing {
    
    // ใน Phase นี้เราจะทำเป็น Mock หรือพิมพ์ Log ไว้ก่อน
    // เพื่อให้ UI ทำงานได้โดยไม่ Error
    func submit(_ report: ReportCase) async throws {
        
        // จำลองการทำงานของ Network (รอ 1 วินาที)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // ตรวจสอบข้อมูลใน Console
        print("--- New Scam Report Received ---")
        print("Reporter: \(report.fullName)")
        print("Phone: \(report.phoneNumber)")
        print("Type: \(report.type)")
        print("Amount: \(report.amount)")
        print("Details: \(report.details)")
        print("-------------------------------")
        
        // TODO: ใน Phase ถัดไป จะเชื่อมต่อกับ Firebase Firestore ที่นี่
    }
}
