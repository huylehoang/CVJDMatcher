//
//  ReasoningService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import CoreML

/// Abstraction for generating explanations from a reasoning model.
protocol ReasoningService {
    func loadModel() throws
    func explain(jd: String, cv: String) throws -> String
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

/// CoreML-based implementation of `ReasoningService`
/// Uses:
/// - `ReasoningTokenizer` to tokenize prompt text into input IDs
/// - `ReasoningDecoder` to decode model logits output into a final string
final class CoreMLReasoningService: ReasoningService {
    private var model: MLModel?
    private let modelName: String
    private let bundle: Bundle
    private let tokenizer: ReasoningTokenizer
    private let maxLength: Int

    /// Create a reasoning service with dependencies injected
    init(
        modelName: String = "ReasoningModel",
        bundle: Bundle = .main,
        tokenizer: ReasoningTokenizer = GPT2ReasoningTokenizer(),
        maxLength: Int = 128
    ) {
        self.modelName = modelName
        self.bundle = bundle
        self.tokenizer = tokenizer
        self.maxLength = maxLength
    }

    /// Load the compiled `.mlmodelc` from the app bundle
    func loadModel() throws {
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ReasoningError.modelNotFound
        }
        let config = MLModelConfiguration()
        model = try MLModel(contentsOf: url, configuration: config)
    }

    /// Generates explanation by tokenizing input → running Core ML model → decoding output logits
    func explain(jd: String, cv: String) throws -> String {
        guard let model else {
            throw ReasoningError.modelNotFound
        }
        // Construct prompt from JD and CV
        let prompt = """
        JD: \(jd)
        CV: \(cv)
        Match? Answer YES or NO
        """
        // Tokenize prompt to input IDs
        let inputIDs = try tokenizer.encode(prompt, maxLength: maxLength)
        // Run Core ML prediction
        let features = try MLDictionaryFeatureProvider(dictionary: ["input_ids": inputIDs])
        let output = try model.prediction(from: features)
        // Get MLMultiArray logits (shape: [1, sequence, vocab])
        guard
            let outputName = model.modelDescription.outputDescriptionsByName.keys.first,
            let logits = output.featureValue(for: outputName)?.multiArrayValue
        else {
            throw ReasoningError.invalidOutput
        }
        // Decode logits to final explanation
        let explanation = try tokenizer.decode(from: logits)
        return explanation
    }
}
