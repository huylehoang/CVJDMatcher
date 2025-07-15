//
//  NLEmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 13/7/25.
//

import NaturalLanguage

final class NLEmbeddingService: EmbeddingService {
    private let language: NLLanguage
    private var model: NLEmbedding?

    init(language: NLLanguage) {
        self.language = language
    }

    func loadModel() async throws {
        guard let model = NLEmbedding.sentenceEmbedding(for: language) else {
            throw EmbeddingError.modelNotFound
        }
        self.model = model
    }

    func embed(_ text: String) throws -> [Float] {
        guard let model = model else {
            throw EmbeddingError.modelNotFound
        }
        guard let vector = model.vector(for: text) else {
            throw EmbeddingError.invalidOutput
        }
        return vector.map { Float($0) }
    }
}

extension NLEmbeddingService {
    static var forEnglish: EmbeddingService {
        NLEmbeddingService(language: .english)
    }
}
