//
//  ContentViewModel.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    private let embeddingService: EmbeddingService
    private let reasoningService: ReasoningService

    @Published var matchResults: [MatchResult] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    let jd = "Looking for an iOS Developer with Swift, Combine"
    private let cvs = [
        "Nguyen A: Senior iOS Developer with Swift and MVVM",
        "Tran B: React Engineer using Next.js and TypeScript",
        "Le C: Android Engineer with Kotlin, Jetpack Compose"
    ]

    init(
        embeddingService: EmbeddingService = CoreMLEmbeddingService(),
        reasoningService: ReasoningService = CoreMLReasoningService()
    ) {
        self.embeddingService = embeddingService
        self.reasoningService = reasoningService
    }

    func runMatchingFlow() {
        isLoading = true
        Task {
            do {
                // Load models (can throw if not found or invalid)
                try embeddingService.loadModel()
                try reasoningService.loadModel()
                // Use Task.detached to run CPU-heavy work off the main thread

                // What is Task.detached?
                // A way to run work **outside of the current actor**, usually off the main thread.
                // It's useful for **heavy computation** that shouldn't block the UI.

                // Why we use Task.detached here?
                // - Embedding + reasoning with Core ML is CPU-intensive
                // - We want to keep the UI responsive
                // - Detached task runs in background without violating MainActor rules
                let results: [MatchResult] = try await Task.detached { [weak self] in
                    guard let self else {
                        return []
                    }
                    // 1. Generate embedding vector for the Job Description
                    let jdVector = try await self.embeddingService.embed(self.jd)
                    // 2. For each CV, compute vector, similarity, and explanation
                    var results: [MatchResult] = []
                    for cv in self.cvs {
                        let cvVector = try await self.embeddingService.embed(cv)
                        let score = await self.cosineSimilarity(jdVector, cvVector)
                        let explanation = try await self.reasoningService.explain(
                            jd: self.jd,
                            cv: cv
                        )
                        results.append(MatchResult(cv: cv, score: score, explanation: explanation))
                    }
                    // 3. Return sorted result by relevance
                    return results.sorted { $0.score > $1.score }
                }.value
                matchResults = results
            } catch {
                // Show any thrown error in UI
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Cosine Similarity

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dot = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dot / (normA * normB)
    }
}
