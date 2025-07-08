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

    @Published var matchResult: MatchResult?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    let jd = "Looking for an iOS Developer with Swift, Combine"
    private let cv = "Nguyen A: Senior iOS Developer with Swift and MVVM"
    //        "Tran B: React Engineer using Next.js and TypeScript",
    //        "Le C: Android Engineer with Kotlin, Jetpack Compose"

    init(
        embeddingService: EmbeddingService = MiniLMEmbeddingService(),
        reasoningService: ReasoningService = Llama2ReasoningService()
    ) {
        self.embeddingService = embeddingService
        self.reasoningService = reasoningService
    }

    func runMatchingFlow() {
        isLoading = true
        reasoningService.onPartialExplanation = { [weak self] explanation in
            if let matchResult = self?.matchResult {
                DispatchQueue.main.async {
                    self?.matchResult = MatchResult(
                        cv: matchResult.cv,
                        score: matchResult.score,
                        explanation: explanation
                    )
                }
            }
        }
        // Use Task.detached to run CPU-heavy work off the main thread

        // What is Task.detached?
        // A way to run work **outside of the current actor**, usually off the main thread.
        // It's useful for **heavy computation** that shouldn't block the UI.

        // Why we use Task.detached here?
        // - Embedding + reasoning with Core ML is CPU-intensive
        // - We want to keep the UI responsive
        // - Detached task runs in background without violating MainActor rules
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                // Load models (can throw if not found or invalid)
                try await self.embeddingService.loadModel()
                try await self.reasoningService.loadModel()

                let jdVector = try await self.embeddingService.embed(self.jd)
                let cvVector = try await self.embeddingService.embed(self.cv)
                let score = await cosineSimilarity(jdVector, cvVector)
                await MainActor.run {
                    self.matchResult = MatchResult(cv: self.cv, score: score, explanation: "")
                }
                let explanation = try await self.reasoningService.explain(jd: self.jd, cv: self.cv)
                await MainActor.run {
                    self.matchResult = MatchResult(
                        cv: self.cv,
                        score: score,
                        explanation: explanation
                    )
                }
            } catch {
                // Show any thrown error in UI
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                self.isLoading = false
            }
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
