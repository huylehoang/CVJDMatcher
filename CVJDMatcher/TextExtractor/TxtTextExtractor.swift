//
//  TxtTextExtractor.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 22/7/25.
//

import Foundation

struct TxtTextExtractor: TextExtractor {
    func extractText(from url: URL) -> String? {
        guard getExtension(for: url) == "txt", let data = try? Data(contentsOf: url) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
        ?? String(data: data, encoding: .ascii)
        ?? String(data: data, encoding: .isoLatin1)
    }
}
