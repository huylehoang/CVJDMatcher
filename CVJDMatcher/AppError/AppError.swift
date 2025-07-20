//
//  AppError.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 20/7/25.
//

import Foundation

enum AppError: Error, LocalizedError {
    case bundleNotFound
    case boxNotFound
    case modelNotFound
    case tokenizerNotFound
    case vocabNotFound
    case invalidInput
    case invalidOutput
    case inferenceTimedOut

    var errorDescription: String? {
        switch self {
        case .bundleNotFound:
            "Bundle not found"
        case .boxNotFound:
            "Box not found"
        case .modelNotFound:
            "Model not found"
        case .tokenizerNotFound:
            "Tokenizer not found"
        case .vocabNotFound:
            "Vocab not found"
        case .invalidInput:
            "Invalid input"
        case .invalidOutput:
            "Invalid output"
        case .inferenceTimedOut:
            "Inference timed out"
        }
    }
}
