//
//  EmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import CoreML

protocol EmbeddingService {
    func loadModel() async throws
    func embed(_ text: String) throws -> [Double]
}

/// Errors that can occur during the embedding process.
enum EmbeddingError: Error, LocalizedError {
    case modelNotFound
    case predictionFailed
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Core ML model not found in the bundle."
        case .predictionFailed:
            return "Failed to make prediction with Core ML model."
        case .invalidOutput:
            return "Embedding output is invalid or missing."
        }
    }
}
