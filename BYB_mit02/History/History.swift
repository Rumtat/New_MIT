//
//  History.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ScanResult] = []

    private let key = "scan_history_v1"

    init() { load() }

    func add(_ r: ScanResult) {
        items.insert(r, at: 0)
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ScanResult].self, from: data) else { return }
        items = decoded
    }
}
