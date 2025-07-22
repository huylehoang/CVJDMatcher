//
//  RtfTextExtractor.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 22/7/25.
//

import Foundation

struct RtfTextExtractor: TextExtractor {
    func extractText(from url: URL) -> String? {
        guard
            getExtension(for: url) == "rtf",
            let data = try? Data(contentsOf: url),
            let attrString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
        else {
            return nil
        }
        return attrString.string
    }
}
