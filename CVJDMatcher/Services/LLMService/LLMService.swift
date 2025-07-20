//
//  ReasoningService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import CoreML

/// Abstraction for generating explanations from a reasoning model.
protocol LLMService: AnyObject {
    typealias ConstructPrompt = (String, String) -> String
    /// Optional callback to report intermediate explanation tokens and their timing
    var onPartialOuput: ((String) -> Void)? { get set }
    /// Generation Timeout in seconds
    var generationTimeoutInSeconds: TimeInterval { get }
    func loadModel() async throws
    func generateResponse(for prompt: String) async throws -> String
}

extension LLMService {
    var onPartialOuput: ((String) -> Void)? {
        get { return nil }
        set { /* ignore if not implemented */ }
    }

    var generationTimeoutInSeconds: TimeInterval {
        120
    }

    func withTimeout<T>(operation: @escaping @Sendable () async throws -> T) async throws -> T {
        let seconds = generationTimeoutInSeconds
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try Task.checkCancellation()
                return try await operation()
            }
            group.addTask {
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AppError.inferenceTimedOut
            }
            guard let result = try await group.next() else {
                throw AppError.inferenceTimedOut
            }
            group.cancelAll()
            return result
        }
    }
}
