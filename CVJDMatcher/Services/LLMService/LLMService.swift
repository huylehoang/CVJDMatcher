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
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw LLMError.inferenceTimedOut
            }
            guard let result = try await group.next() else {
                throw LLMError.inferenceTimedOut
            }
            group.cancelAll()
            return result
        }
    }
}

/// Errors related to Core ML model loading or inference failures.
enum LLMError: Error, LocalizedError {
    case modelNotFound
    case tokenizerNotFound
    case predictionFailed
    case outputMissing
    case invalidInput
    case invalidOutput
    case inferenceTimedOut

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            "Core ML reasoning model not found."
        case .tokenizerNotFound:
            "Tokenizer not found."
        case .predictionFailed:
            "Failed to run prediction with reasoning model."
        case .outputMissing:
            "No explanation found in model output."
        case .invalidInput:
            "Invalid input format found in model input."
        case .invalidOutput:
            "Invalid explanation format found in model output."
        case .inferenceTimedOut:
            "Response generation timed out."
        }
    }
}
