//
//  LinkPreviewView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 18/1/2569 BE.
//
//
//
//  LinkPreviewView.swift
//  BYB_mit02
//

import SwiftUI
import WebKit

struct LinkPreviewView: View {
    let urlString: String
    @StateObject private var vm = WebTileSnapshotViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("กำลังสร้างภาพตัวอย่างหน้าเว็บ…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 260)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            } else if !vm.tiles.isEmpty {
                // ✅ แสดงเป็นหลายภาพ เลื่อนดูได้ รายละเอียดชัด (ไม่ย่อทั้งหน้า)
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.tiles.indices, id: \.self) { i in
                            Image(uiImage: vm.tiles[i])
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                        }
                    }
                    .padding(12)
                }
                .frame(height: 320) // ✅ กรอบ preview (ปรับได้)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .allowsHitTesting(true) // เลื่อนดูได้ (แต่ไม่ใช่เว็บจริง เลยไม่กดลิงก์)

            } else {
                // fallback
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ไม่สามารถสร้างภาพตัวอย่างหน้าเว็บได้")
                            .font(.subheadline.weight(.semibold))
                        Text(vm.displayUrlText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 260)
                .padding(.horizontal, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .task(id: urlString) {
            await vm.load(urlString: urlString)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class WebTileSnapshotViewModel: ObservableObject {
    @Published var tiles: [UIImage] = []
    @Published var isLoading: Bool = false

    private(set) var displayUrlText: String = ""

    private static var cache: [String: [UIImage]] = [:]

    func load(urlString: String) async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = Self.makeURL(from: trimmed) else {
            displayUrlText = trimmed
            tiles = []
            isLoading = false
            return
        }

        let key = url.absoluteString
        displayUrlText = key

        if let cached = Self.cache[key] {
            tiles = cached
            isLoading = false
            return
        }

        isLoading = true
        tiles = []

        let loader = WebTileSnapshotLoader(url: url)

        do {
            let imgs = try await loader.loadAndSnapshotTiles(timeoutSeconds: 12)
            Self.cache[key] = imgs
            tiles = imgs
            isLoading = false
        } catch {
            tiles = []
            isLoading = false
        }
    }

    private static func makeURL(from raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if let url = URL(string: s), url.scheme != nil { return url }
        if s.contains(".") && !s.contains(" ") { return URL(string: "https://\(s)") }
        return nil
    }
}

// MARK: - Loader (Tile snapshots)

final class WebTileSnapshotLoader: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private let url: URL

    private var continuation: CheckedContinuation<[UIImage], Error>?
    private var didFinishOnce = false

    private let viewportWidth: CGFloat = 390
    private let tileHeight: CGFloat = 720        // ✅ ความสูงแต่ละชิ้น (ปรับได้)
    private let maxTotalHeight: CGFloat = 3600   // ✅ จำกัดความยาวรวม (กันเครื่องค้าง)

    init(url: URL) {
        self.url = url

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        self.webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: viewportWidth, height: tileHeight),
            configuration: config
        )

        super.init()

        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        // ✅ ให้เว็บ render แบบมือถือมากขึ้น
        webView.customUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    }

    func loadAndSnapshotTiles(timeoutSeconds: TimeInterval) async throws -> [UIImage] {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[UIImage], Error>) in
            self.continuation = cont

            let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutSeconds)
            webView.load(req)

            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
                guard let self else { return }
                if self.continuation != nil {
                    self.finish(.failure(NSError(domain: "WebTileSnapshot", code: -1001)))
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !didFinishOnce else { return }
        didFinishOnce = true

        // ✅ รอให้ DOM/รูป/ฟอนต์ มาทันก่อน (YouTube/เว็บใหญ่ต้องรอนิดนึง)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self else { return }

            let jsHeight = """
            Math.max(
              document.body.scrollHeight,
              document.documentElement.scrollHeight,
              document.body.offsetHeight,
              document.documentElement.offsetHeight
            );
            """

            self.webView.evaluateJavaScript(jsHeight) { value, _ in
                let raw = (value as? NSNumber)?.doubleValue ?? 1200
                let pageHeight = min(CGFloat(raw), self.maxTotalHeight)

                let count = Int(ceil(pageHeight / self.tileHeight))
                self.snapshotTiles(count: max(1, count), pageHeight: pageHeight)
            }
        }
    }

    private func snapshotTiles(count: Int, pageHeight: CGFloat) {
        var images: [UIImage] = []
        images.reserveCapacity(count)

        func take(at index: Int) {
            if index >= count {
                finish(.success(images))
                return
            }

            let y = CGFloat(index) * tileHeight
            let h = min(tileHeight, max(200, pageHeight - y))

            let cfg = WKSnapshotConfiguration()
            cfg.afterScreenUpdates = true
            cfg.rect = CGRect(x: 0, y: y, width: viewportWidth, height: h)

            webView.takeSnapshot(with: cfg) { img, err in
                if let img = img {
                    images.append(img)
                    take(at: index + 1)
                } else {
                    self.finish(.failure(err ?? NSError(domain: "WebTileSnapshot", code: -1)))
                }
            }
        }

        take(at: 0)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<[UIImage], Error>) {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(with: result)
    }
}
