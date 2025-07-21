//
//  UploadFilesView.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 21/7/25.
//

import SwiftUI
import PDFKit

struct UploadFilesView: View {
    private struct CVPreviewItem: Identifiable {
        let id = UUID()
        let name: String
        let content: String
    }

    @Environment(\.dismiss) private var dismiss
    @State private var jd: String = ""
    @State private var cvs: [(url: URL, content: String)] = []
    @State private var showJDImporter = false
    @State private var showCVImporter = false
    @State private var showJDPreview = false
    @State private var selectedCVPreview: (CVPreviewItem)?
    let onApply: (MatchingInputData) -> Void

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Job Description").font(.headline)) {
                    Button("📄 Select JD File") {
                        showJDImporter = true
                    }
                    .fileImporter(
                        isPresented: $showJDImporter,
                        allowedContentTypes: [.plainText, .pdf],
                        allowsMultipleSelection: false
                    ) { result in
                        if let url = try? result.get().first {
                            if let text = extractText(from: url) {
                                jd = text
                            }
                        }
                    }
                    if !jd.isEmpty {
                        Button(action: {
                            showJDPreview = true
                        }) {
                            Text("✅ JD loaded (\(jd.count) characters)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                Section(header: Text("Candidate CVs").font(.headline)) {
                    Button("📄 Select CV Files") {
                        showCVImporter = true
                    }
                    .fileImporter(
                        isPresented: $showCVImporter,
                        allowedContentTypes: [.plainText, .pdf],
                        allowsMultipleSelection: true
                    ) { result in
                        if let urls = try? result.get() {
                            var results: [(url: URL, content: String)] = []
                            for url in urls {
                                if let text = extractText(from: url) {
                                    results.append((url: url, content: text))
                                }
                            }
                            cvs = results
                        }
                    }
                    if !cvs.isEmpty {
                        ForEach(cvs, id: \.url) { item in
                            HStack {
                                Text("• \(item.url.lastPathComponent)")
                                    .font(.subheadline)
                                Spacer()
                                Button(action: {
                                    selectedCVPreview = CVPreviewItem(
                                        name: item.url.lastPathComponent,
                                        content: item.content
                                    )
                                }) {
                                    Text("Preview")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Upload Files")
            .toolbar {
                if !jd.isEmpty && !cvs.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            onApply(MatchingInputData(jd: jd, cvs: cvs.map { $0.content }))
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showJDPreview) {
                ScrollView {
                    Text(jd)
                        .padding()
                }
                .navigationTitle("JD Preview")
            }
            .sheet(item: $selectedCVPreview) { item in
                ScrollView {
                    Text(item.content)
                        .padding()
                }
                .navigationTitle(item.name)
            }
        }
    }

    private func extractText(from url: URL) -> String? {
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        let ext = url.pathExtension.lowercased()
        if ext == "txt" {
            if let data = try? Data(contentsOf: url),
               let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .ascii)
                ?? String(data: data, encoding: .isoLatin1) {
                return text
            }
        } else if ext == "pdf" {
            if let pdfDoc = PDFDocument(url: url) {
                return (0..<pdfDoc.pageCount)
                    .compactMap {
                        pdfDoc.page(at: $0)?.string
                    }
                    .joined(separator: "\n")
            }
        }
        return nil
    }
}
