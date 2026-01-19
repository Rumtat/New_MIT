//
//  History.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

//
//  ScanHistoryStore.swift
//  BYB_mit02
//

import Foundation

@MainActor
final class ScanHistoryStore: ObservableObject {
    static let shared = ScanHistoryStore()

    @Published private(set) var items: [ScanResult] = []

    private let storageKey = "scan_history_v1"

    init() { load() }

    func add(_ result: ScanResult) {
        items.insert(result, at: 0)
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    func delete(_ result: ScanResult) {
        items.removeAll { $0.id == result.id }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ScanResult].self, from: data)
        else { return }
        items = decoded
    }
}
