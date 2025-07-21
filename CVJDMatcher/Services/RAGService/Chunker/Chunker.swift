//
//  Chunker.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

protocol Chunker {
    func chunk(text: String) throws -> [Chunk]
    func embedWithChunking(text: String, using embeddingService: EmbeddingService) throws -> [Float]
}

extension Chunker {
    func embedWithChunking(
        text: String,
        using embeddingService: EmbeddingService
    ) throws -> [Float] {
        let chunks = try chunk(text: text)
        if chunks.isEmpty {
            return try embeddingService.embed(text)
        }
        let embeddings = try chunks.map { try embeddingService.embed($0.text) }
        return average(embeddings: embeddings)
    }

    private func average(embeddings: [[Float]]) -> [Float] {
        guard !embeddings.isEmpty else { return [] }
        let dimension = embeddings[0].count
        var sum = [Float](repeating: 0, count: dimension)
        for vec in embeddings {
            sum = zip(sum, vec).map(+)
        }
        return sum.map { $0 / Float(embeddings.count) }
    }
}
