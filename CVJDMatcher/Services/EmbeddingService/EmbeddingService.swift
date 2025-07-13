//
//  EmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import Accelerate

protocol EmbeddingService {
    func loadModel() async throws
    func embed(_ text: String) throws -> [Double]
    func cosine(_ a: [Double], _ b: [Double]) -> Double
}

extension EmbeddingService {
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
    func cosine(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count && !a.isEmpty else {
            return 0
        }
        let n = vDSP_Length(a.count)
        var dot: Double = 0, magA: Double = 0, magB: Double = 0
        vDSP_dotprD(a, 1, b, 1, &dot, n)           // dot product
        vDSP_svesqD(a, 1, &magA, n)                // sum of squares of a
        vDSP_svesqD(b, 1, &magB, n)                // sum of squares of b
        guard magA > 0, magB > 0 else {
            return 0
        }
        let denom = sqrt(magA) * sqrt(magB)
        return dot / denom
    }

//    func cosine(_ a: [Double], _ b: [Double]) -> Double {
//        func normalize(_ v: [Double]) -> [Double] {
//            let mag = sqrt(v.map { $0 * $0 }.reduce(0, +)) + 1e-8
//            return v.map { $0 / mag }
//        }
//        let na = normalize(a)
//        let nb = normalize(b)
//        return zip(na, nb).map(*).reduce(0, +)
//    }
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
