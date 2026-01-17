//
//  Document Picker.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentImportButton: View {
    var onText: (String) -> Void
    @State private var showPicker = false

    var body: some View {
        Button("Import File") { showPicker = true }
            .sheet(isPresented: $showPicker) {
                DocumentPicker { url in
                    onText(readText(from: url) ?? "")
                }
            }
    }

    private func readText(from url: URL) -> String? {
        // security-scoped
        let canAccess = url.startAccessingSecurityScopedResource()
        defer { if canAccess { url.stopAccessingSecurityScopedResource() } }

        // TXT
        if url.pathExtension.lowercased() == "txt" {
            return try? String(contentsOf: url, encoding: .utf8)
        }

        // PDF (MVP: ดึง text แบบง่าย)
        if url.pathExtension.lowercased() == "pdf",
           let pdf = PDFDocument(url: url) {
            var out = ""
            for i in 0..<pdf.pageCount {
                out += (pdf.page(at: i)?.string ?? "") + "\n"
            }
            return out.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.plainText, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
