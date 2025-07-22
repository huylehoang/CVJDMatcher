//
//  StandardTextExtractor.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 22/7/25.
//

import Foundation

struct StandardTextExtractor: TextExtractor {
    static var defaultTextExtractor: [TextExtractor] {
        [TxtTextExtractor(), PdfTextExtractor(), RtfTextExtractor()]
    }

    private let textExtractors: [TextExtractor]

    init(textExtractors: [TextExtractor] = StandardTextExtractor.defaultTextExtractor) {
        self.textExtractors = textExtractors
    }

    func extractText(from url: URL) -> String? {
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        for extractor in textExtractors {
            if let text = extractor.extractText(from: url),
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}
