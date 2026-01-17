//
//  Reportcase.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 11/1/2569 BE.
//

import Foundation

struct ReportCase: Codable {
    let fullName: String      // เพิ่มให้ตรงกับ UI ใหม่
    let phoneNumber: String
    let bankAccount: String
    let email: String
    let type: String          // ประเภทการโกง
    let date: Date            // วันที่ได้รับข้อมูล
    let amount: Double        // จำนวนเงิน
    let details: String
    
    // แบบย่อสำหรับใช้ใน Service เดิม
    init(type: String, value: String, details: String, fullName: String = "", phoneNumber: String = "", bankAccount: String = "", email: String = "", date: Date = Date(), amount: Double = 0) {
        self.type = type
        self.value = value // ค่าหลักที่ใช้ตรวจสอบ (เช่น เบอร์หรือบัญชี)
        self.details = details
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.bankAccount = bankAccount
        self.email = email
        self.date = date
        self.amount = amount
    }
    
    private let value: String // สำหรับ backward compatibility
}


