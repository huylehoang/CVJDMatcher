//
//  StandardRAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

import Foundation

/// A local Retrieval-Augmented Generation (RAG) service:
/// 1. Embeds job description and CVs
/// 2. Splits (chunks) long CVs to embed more effectively
/// 3. Calculates cosine similarity, filters by threshold, and picks top matches
/// 4. Uses an LLM-based LLMService to explain each match, with partial updates
final class StandardRAGService: RAGService {
    private var embeddings: [[Double]] = []
    private var data: [String] = []
    private let embeddingService: EmbeddingService
    private let llmService: LLMService
    private let chunker: Chunker
    private let topK: Int

    init(
        embeddingService: EmbeddingService = MiniLMEmbeddingService(),
        llmService: LLMService = MediaPipeLLMService.gemma_2b_it_cpu_int8,
        chunker: Chunker = SlidingWindowChunker(),
        topK: Int = 3
    ) {
        self.embeddingService = embeddingService
        self.llmService = llmService
        self.chunker = chunker
        self.topK = topK
    }

    func setup() async throws {
        try await embeddingService.loadModel()
        try await llmService.loadModel()
    }

    /// Load and embed a list of CVs
    func indexData(_ data: [String]) throws {
        self.data = data
        embeddings = try data.map { cv in
            // -- Split long CV into chunks for better embedding
            let chunks = try chunker.chunk(text: cv)
            if chunks.isEmpty {
                // If CV is short, embed the full string
                return try embeddingService.embed(cv)
            }
            // Otherwise, embed each chunk separately
            let chunkEmbeds = try chunks.map { try embeddingService.embed($0.text) }
            // Compute the average embedding vector for the CV
            return chunkEmbeds
                .reduce([Double](repeating: 0, count: chunkEmbeds[0].count)) { acc, vec in
                    zip(acc, vec).map(+)
                }
                .map { $0 / Double(chunkEmbeds.count) }
        }
    }

    /// Given a JD, find top-K matching CVs (above threshold) and generate explanations
    func generateReponse(for query: String, onPartial: ((String) -> Void)?) async throws -> String {
        // Embed the job description
        let jdVec = try embeddingService.embed(query)
        // Score each CV embedding using cosine similarity
        let matchResults = embeddings
            .enumerated()
            .map { MatchResult(cv: data[$0], score: embeddingService.cosine(jdVec, $1)) }
            .sorted { $0.score > $1.score } // Sort by descending score
            .prefix(topK) // pick top K
        if matchResults.isEmpty {
            // Return placeholder if no matches found
            return "No CVs Founded"
        }
        llmService.onPartialOuput = {
            onPartial?($0.cleanedResponse)
        }
        let prompt = PromptProvider.multiCandidatePrompt(
            jd: query,
            results: Array(matchResults),
            topK: topK
        )
        let response = try await llmService.generateResponse(for: prompt)
        return response.cleanedResponse
    }
}

private extension String {
    var cleanedResponse: String {
        replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
