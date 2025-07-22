//
//  TextExtractor.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 22/7/25.
//

import Foundation

protocol TextExtractor {
    func extractText(from url: URL) -> String?
}

extension TextExtractor {
    func getExtension(for url: URL) -> String {
        return url.pathExtension.lowercased()
    }
}
