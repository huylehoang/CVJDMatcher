//
//  VocabLoader.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 20/7/25.
//

import Foundation

enum VocabLoader {
    static func load(vocabName: String, bundle: Bundle = .main) throws -> [String: Int] {
        guard let vocabUrl = bundle.url(forResource: vocabName, withExtension: "json") else {
            throw AppError.vocabNotFound
        }
        let data = try Data(contentsOf: vocabUrl)
        let vocab = try JSONDecoder().decode([String: Int].self, from: data)
        return vocab
    }
}
