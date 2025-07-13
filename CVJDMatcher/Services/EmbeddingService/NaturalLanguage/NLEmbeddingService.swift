//
//  NLEmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 13/7/25.
//

import NaturalLanguage
import Accelerate

final class NLEmbeddingService: EmbeddingService {
    private var model: NLEmbedding?

    func loadModel() async throws {
        guard let model = NLEmbedding.sentenceEmbedding(for: .english) else {
            throw EmbeddingError.modelNotFound
        }
        self.model = model
    }

    func embed(_ text: String) throws -> [Double] {
        guard let model = model else {
            throw EmbeddingError.modelNotFound
        }
        guard let vector = model.vector(for: text) else {
            throw EmbeddingError.invalidOutput
        }
        return vector
    }
}
