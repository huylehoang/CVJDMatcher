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
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            "Core ML reasoning model not found."
        case .predictionFailed:
            "Failed to run prediction with reasoning model."
        case .outputMissing:
            "No explanation found in model output."
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
    private let decoder: ReasoningDecoder
    private let maxLength: Int

    /// Create a reasoning service with dependencies injected
    init(
        modelName: String = "ReasoningModel",
        bundle: Bundle = .main,
        tokenizer: ReasoningTokenizer = GPT2ReasoningTokenizer(),
        decoder: ReasoningDecoder = GPT2ReasoningDecoder(),
        maxLength: Int = 128
    ) {
        self.modelName = modelName
        self.bundle = bundle
        self.tokenizer = tokenizer
        self.decoder = decoder
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
        // 1. Construct prompt from JD and CV
        let prompt = """
        You are an expert AI assistant for job candidate matching.

        Given a job description (JD) and a candidate's CV, \
        analyze whether the candidate is a good fit. Then:

        1. Output: "Match: YES" or "Match: NO"
        2. Output: "Score: [0.0 – 1.0]" confidence score
        3. Output: "Reason: [short explanation in 3–5 steps]"

        Please evaluate based on:
        - Skills and technologies
        - Years of experience
        - Domain alignment
        - Gaps or mismatches
        - Communication or project fit

        Example:

        JD:
        We are hiring a Senior iOS Developer with 3+ years of experience in \
        Swift, UIKit, and MVVM. Knowledge of RxSwift is a plus.

        CV:
        Nguyen A has 5 years of iOS development experience. Skilled in \
        Swift, UIKit, and MVVM. Used RxSwift in 2 projects. Published 3 apps to App Store.

        Explanation:
        Match: YES  
        Score: 0.89  
        Reason:  
        1. Candidate exceeds experience requirement.  
        2. Core skills (Swift, UIKit, MVVM) match exactly.  
        3. Has RxSwift experience (preferred).  
        4. Published apps show practical impact.  
        Conclusion: Strong alignment.

        Now analyze the following:

        JD:
        \(jd)

        CV:
        \(cv)

        Explanation:
        """
        // 2. Tokenize prompt to input IDs
        let inputIDs = try tokenizer.tokenize(prompt, maxLength: maxLength)
        // 3. Convert to MLMultiArray
        let inputArray = try MLMultiArrayUtils.int32(from: inputIDs, shape: [1, maxLength])
        // 4. Run Core ML prediction
        let features = try MLDictionaryFeatureProvider(dictionary: ["input_ids": inputArray])
        let output = try model.prediction(from: features)
        // 5. Get MLMultiArray logits (shape: [1, sequence, vocab])
        guard
            let outputName = model.modelDescription.outputDescriptionsByName.keys.first,
            let logits = output.featureValue(for: outputName)?.multiArrayValue
        else {
            throw ReasoningError.invalidOutput
        }
        // 6. Decode logits to final explanation
        let explanation = try decoder.decode(from: logits)
        return explanation
    }
}
