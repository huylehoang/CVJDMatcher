//
//  LocalRAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

import Foundation

/// A local Retrieval-Augmented Generation (RAG) service:
/// 1. Embeds job description and CVs
/// 2. Splits (chunks) long CVs to embed more effectively
/// 3. Calculates cosine similarity, filters by threshold, and picks top matches
/// 4. Uses an LLM-based ReasoningService to explain each match, with partial updates
final class LocalRAGService: RAGService {
    private var embeddings: [[Double]] = []
    private var cvs: [String] = []
    private let embeddingService: EmbeddingService
    private let reasoningService: ReasoningService
    private let chunker: Chunker
    private let topK: Int
    private let minScore: Double

    init(
        embeddingService: EmbeddingService = MiniLMEmbeddingService(),
        reasoningService: ReasoningService = Llama2ReasoningService(),
        chunker: Chunker = SlidingWindowChunker(),
        topK: Int = 1,
        minScore: Double = 0.8
    ) {
        self.embeddingService = embeddingService
        self.reasoningService = reasoningService
        self.chunker = chunker
        self.topK = topK
        self.minScore = minScore
    }

    func loadModels() async throws {
        try await embeddingService.loadModel()
        try await reasoningService.loadModel()
    }

    /// Load and embed a list of CVs
    func loadData(_ cvs: [String]) throws {
        self.cvs = cvs
        embeddings = try cvs.map { cv in
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
    func query(jd: String, onPartial: (([MatchResult]) -> Void)?) throws -> [MatchResult] {
        // Embed the job description
        let jdVec = try embeddingService.embed(jd)
        // Score each CV embedding using cosine similarity
        let results = embeddings
            .enumerated()
            .compactMap { (i, vec) -> MatchResult? in
                let score = cosine(jdVec, vec)
                guard score >= minScore else {
                    return nil
                }
                return MatchResult(cv: cvs[i], score: score, explanation: "")
            }
            .sorted { $0.score > $1.score } // Sort by descending score
            .prefix(topK) // pick top K
        if results.isEmpty {
            // Return placeholder if no matches found
            return [MatchResult(cv: "No CVs Founded", score: 0.0, explanation: "")]
        }
        var finalResults = [MatchResult]()
        for result in results {
            finalResults.append(result)
            let cv = result.cv
            // Called when partial explanation is generated
            let onPartialExplanation: (String) -> Void = { explanation in
                finalResults[finalResults.count - 1] = MatchResult(
                    cv: cv,
                    score: result.score,
                    explanation: explanation
                )
                onPartial?(finalResults)
            }
            reasoningService.onPartialExplanation = onPartialExplanation
            let explanation = try reasoningService.explain(jd: jd, cv: cv)
            onPartialExplanation(explanation)
        }
        return finalResults
    }

    // MARK: - Cosine Similarity
    /// Computes similarity between vectors A and B:
    /// similarity = (A ⋅ B) / (||A|| * ||B|| + ε)
    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        let dot = zip(a, b).map(*).reduce(0, +)
        let magA = sqrt(a.map { $0*$0 }.reduce(0, +))
        let magB = sqrt(b.map { $0*$0 }.reduce(0, +))
        return dot / (magA * magB + 1e-8)
    }
}
