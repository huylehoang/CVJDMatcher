//
//  ReasoningService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import CoreML

/// Abstraction for generating explanations from a reasoning model.
protocol ReasoningService: AnyObject {
    typealias ConstructPrompt = (String, String) -> String
    /// Optional callback to report intermediate explanation tokens and their timing
    var onPartialExplanation: ((String) -> Void)? { get set }
    var constructPrompt: ConstructPrompt { get set }
    func loadModel() async throws
    func explain(jd: String, cv: String) async throws -> String
}

extension ReasoningService {
    var onPartialExplanation: ((String) -> Void)? {
        get { return nil }
        set { /* ignore if not implemented */ }
    }
}

/// Errors related to Core ML model loading or inference failures.
enum ReasoningError: Error, LocalizedError {
    case modelNotFound
    case predictionFailed
    case outputMissing
    case invalidInput
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            "Core ML reasoning model not found."
        case .predictionFailed:
            "Failed to run prediction with reasoning model."
        case .outputMissing:
            "No explanation found in model output."
        case .invalidInput:
            "Invalid input format found in model input."
        case .invalidOutput:
            "Invalid explanation format found in model output."
        }
    }
}
