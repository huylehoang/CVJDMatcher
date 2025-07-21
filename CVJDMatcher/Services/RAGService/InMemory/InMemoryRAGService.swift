//
//  InMemoryRAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

import Foundation
import Accelerate

/// A local Retrieval-Augmented Generation (RAG) service:
/// 1. Embeds job description and CVs
/// 2. Splits (chunks) long CVs to embed more effectively
/// 3. Calculates cosine similarity, filters by threshold, and picks top matches
/// 4. Uses an LLM-based LLMService to explain each match, with partial updates
final class InMemoryRAGService: RAGService {
    private var embeddings: [[Float]] = []
    private var data: [String] = []
    private let embeddingService: EmbeddingService
    private let llmService: LLMService
    private let promptService: PromptService
    private let chunker: Chunker
    private let topK: Int

    init(
        embeddingService: EmbeddingService = MiniLMEmbeddingService(),
        llmService: LLMService = MediaPipeLLMService.gemma_2b_it_cpu_int8,
        promptService: PromptService = PromptServiceV1(),
        chunker: Chunker = SlidingWindowChunker(),
        topK: Int = 3
    ) {
        self.embeddingService = embeddingService
        self.llmService = llmService
        self.promptService = promptService
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
        embeddings = try data.map { text in
            try chunker.embedWithChunking(text: text, using: embeddingService)
        }
    }

    /// Given a JD, find top-K matching CVs (above threshold) and generate explanations
    func generateReponse(for query: String, onPartial: ((String) -> Void)?) async throws -> String {
        // Embed the job description
        let jdVec = try embeddingService.embed(query)
        // Score each CV embedding using cosine similarity
        let matchResults = embeddings
            .enumerated()
            .map { MatchResult(cv: data[$0], score: cosine(jdVec, $1)) }
            .sorted { $0.score > $1.score } // Sort by descending score
            .prefix(topK) // pick top K
        if matchResults.isEmpty {
            // Return placeholder if no matches found
            return emptyResponse
        }
        llmService.onPartialOuput = {
            onPartial?($0.cleanedLLMResponse)
        }
        let prompt = promptService.prompt(
            jd: query,
            cvs: Array(matchResults).cvs,
            topK: topK
        )
        let response = try await llmService.generateResponse(for: prompt)
        return response.cleanedLLMResponse
    }


    // MARK: - Cosine Similarity
    /// Computes cosine similarity between two embedding vectors A and B.
    ///
    /// Formula:
    /// similarity = (A ⋅ B) / (||A|| * ||B|| + ε)
    ///
    /// Where:
    /// - A ⋅ B: dot product of vectors A and B
    /// - ||A|| and ||B||: magnitudes (L2 norm) of the vectors
    /// - ε: a small constant (1e-8) to avoid division by zero
    ///
    /// Cosine similarity returns a score between -1 and 1, where:
    /// - 1 means the vectors are identical in direction (perfect match)
    /// - 0 means the vectors are orthogonal (no relation)
    /// - -1 means the vectors are opposite (opposite meaning)
    ///
    /// In this RAG flow:
    /// - Each CV is embedded into a vector (using MiniLM).
    /// - The job description (JD) is also embedded.
    /// - We compute cosine similarity between the JD vector and each CV vector.
    /// - The higher the score, the more semantically similar the CV is to the JD.
    ///
    /// Example:
    /// - JD: "Looking for iOS Developer with Swift, Combine"
    /// - CV1: "Senior iOS Engineer with Swift and MVVM"
    /// - Cosine similarity score ≈ 0.89 → likely a match.
    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count && !a.isEmpty else {
            return 0
        }
        let n = vDSP_Length(a.count)
        var dot: Float = 0, magA: Float = 0, magB: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dot, n)           // dot product
        vDSP_svesq(a, 1, &magA, n)                // sum of squares of a
        vDSP_svesq(b, 1, &magB, n)                // sum of squares of b
        guard magA > 0, magB > 0 else {
            return 0
        }
        let denom = sqrt(magA) * sqrt(magB)
        return dot / denom
    }

    //    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
    //        func normalize(_ v: [Double]) -> [Double] {
    //            let mag = sqrt(v.map { $0 * $0 }.reduce(0, +)) + 1e-8
    //            return v.map { $0 / mag }
    //        }
    //        let na = normalize(a)
    //        let nb = normalize(b)
    //        return zip(na, nb).map(*).reduce(0, +)
    //    }
}

extension String {
    var cleanedLLMResponse: String {
        replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension [MatchResult] {
    var cvs: String {
        enumerated()
            .map { "Candidate \($0 + 1): \($1.cleanedCV)" }
            .joined(separator: "\n\n")
    }
}

private extension MatchResult {
    var cleanedCV: String {
        cv.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
