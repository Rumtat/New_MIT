//
//  BYB_mit02App.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // ✅ เริ่มการทำงานของ Firebase (ทั้ง Auth และ Firestore)
        FirebaseApp.configure()
        return true
    }
}

@main
struct BYB_mit02App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // ✅ เก็บสถานะการดูคู่มือ (ถ้ายังไม่มีค่าจะเป็น false โดยอัตโนมัติ)
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
            }
            // ✅ ถ้า hasSeenOnboarding เป็น false ให้เด้งหน้า Onboarding ขึ้นมา
            .fullScreenCover(isPresented: .init(
                get: { !hasSeenOnboarding },
                set: { _ in }
            )) {
                UserGuideView()
            }
        }
    }
}
