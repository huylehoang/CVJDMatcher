//
//  PdfTextExtractor.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 22/7/25.
//

import PDFKit

struct PdfTextExtractor: TextExtractor {
    func extractText(from url: URL) -> String? {
        guard getExtension(for: url) == "pdf", let pdfDoc = PDFDocument(url: url) else {
            return nil
        }
        let text = (0..<pdfDoc.pageCount)
            .compactMap { pdfDoc.page(at: $0)?.string }
            .joined(separator: "\n")
        return text.isEmpty ? nil : text
    }
}
