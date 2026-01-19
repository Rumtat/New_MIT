//
//  LinkWhitelistStore.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 18/1/2569 BE.
//


//
//  LinkRepository.swift
//  BYB_mit02
//

import Foundation
import FirebaseFirestore

@MainActor
final class LinkRepository: ObservableObject {

    // Singleton
    static let shared = LinkRepository()

    @Published private(set) var isReady: Bool = false
    @Published private(set) var lastError: String? = nil

    private var domainToName: [String: String] = [:]
    private var hasLoadedOnce = false

    private init() {}

    /// Call once on app start (or before first scan)
    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        await reloadFromServer()
    }

    /// Force reload from Firestore
    func reloadFromServer() async {
        isReady = false
        lastError = nil
        domainToName.removeAll()

        do {
            let snap = try await Firestore.firestore()
                .collection("link_confirmed")
                .getDocuments()

            var map: [String: String] = [:]

            for doc in snap.documents {
                let data = doc.data()
                let displayName = (data["id"] as? String) ?? doc.documentID

                if let urlStr = data["url"] as? String,
                   let host = Self.extractHost(from: urlStr) {
                    map[host] = displayName
                }
            }

            domainToName = map
            isReady = true
        } catch {
            lastError = error.localizedDescription
            isReady = true
        }
    }

    /// Lookup display name if the URL is in confirmed-safe list
    func lookupName(for rawUrl: String) -> String? {
        guard let host = Self.extractHost(from: rawUrl) else { return nil }
        return domainToName[host]
    }

    /// Quick check: is this URL confirmed-safe?
    func isSafe(_ rawUrl: String) -> Bool {
        lookupName(for: rawUrl) != nil
    }

    // MARK: - Helpers

    private static func normalizeURL(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "" }

        if s.lowercased().hasPrefix("http://") || s.lowercased().hasPrefix("https://") {
            return s
        }

        if s.contains(".") && !s.contains(" ") {
            return "https://\(s)"
        }

        return s
    }

    private static func extractHost(from raw: String) -> String? {
        let normalized = normalizeURL(raw)
        guard let url = URL(string: normalized),
              let host = url.host?.lowercased()
        else { return nil }

        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }
}
