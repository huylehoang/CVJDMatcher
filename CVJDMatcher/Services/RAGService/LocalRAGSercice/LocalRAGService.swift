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
/// 4. Uses an LLM-based LLMService to explain each match, with partial updates
final class LocalRAGService: RAGService {
    private var embeddings: [[Double]] = []
    private var cvs: [String] = []
    private let embeddingService: EmbeddingService
    private let llmService: LLMService
    private let chunker: Chunker
    private let topK: Int
    private let minScore: Double

    init(
        embeddingService: EmbeddingService = MiniLMEmbeddingService(),
        llmService: LLMService = MediaPipeLLMService.gemma_2b_it_cpu_int8,
        chunker: Chunker = SlidingWindowChunker(),
        topK: Int = 1,
        minScore: Double = 0.8
    ) {
        self.embeddingService = embeddingService
        self.llmService = llmService
        self.chunker = chunker
        self.topK = topK
        self.minScore = minScore
    }

    func setup() async throws {
        try await embeddingService.loadModel()
        try await llmService.loadModel()
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
    func query(jd: String, onPartial: ((String) -> Void)?) async throws -> String {
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
            return "No CVs Founded"
        }
        var finalResults = [MatchResult]()
        for result in results {
            finalResults.append(result)
            onPartial?(finalResults.description)
            let cv = result.cv
            // Called when partial explanation is generated
            let onPartialOuput: (String) -> Void = { explanation in
                finalResults[finalResults.count - 1] = MatchResult(
                    cv: cv,
                    score: result.score,
                    explanation: explanation
                )
                onPartial?(finalResults.description)
            }
            llmService.onPartialOuput = onPartialOuput
            let prompt = constructPrompt(jd: jd, cv: cv, scoreString: result.scoreString)
            let explanation = try await llmService.generate(prompt: prompt)
            onPartialOuput(explanation)
        }
        return finalResults.description
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
    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        let dot = zip(a, b).map(*).reduce(0, +)
        let magA = sqrt(a.map { $0*$0 }.reduce(0, +))
        let magB = sqrt(b.map { $0*$0 }.reduce(0, +))
        return dot / (magA * magB + 1e-8)
    }

    private func constructPrompt(jd: String, cv: String, scoreString: String) -> String {
        """
        You are a system that analyzes whether a Candidate CV fits a Job Description.

        Based on the similarity score of \(scoreString), explain why the Candidate CV is \
        (or is not) a good match for the job. Focus only on technical fit \
        (skills, tools, experience). Keep your reasoning aligned with the given score.

        Job Description:
        \(jd)

        Candidate CV:
        \(cv)

        Now explain:
        """
    }
}

private extension [MatchResult] {
    var description: String {
        map { $0.resultDesciption }.joined(separator: "\n")
    }
}
