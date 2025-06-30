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

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Core ML reasoning model not found."
        case .predictionFailed:
            return "Failed to run prediction with reasoning model."
        case .outputMissing:
            return "No explanation found in model output."
        }
    }
}

/// CoreML-based implementation of `ReasoningService`.
/// This class loads a reasoning LLM model (e.g. distilgpt2 converted to Core ML)
/// and uses it to generate natural language explanations from prompt text.
final class CoreMLReasoningService: ReasoningService {
    private var model: MLModel?
    private let modelName: String
    private let bundle: Bundle

    init(modelName: String = "ReasoningModel", bundle: Bundle = .main) {
        self.modelName = modelName
        self.bundle = bundle
    }

    /// Load the `.mlmodelc` from the bundle at runtime.
    func loadModel() throws {
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ReasoningError.modelNotFound
        }
        let config = MLModelConfiguration()
        model = try MLModel(contentsOf: url, configuration: config)
    }

    /// Generate a natural-language explanation by running the prompt through the LLM model.
    func explain(jd: String, cv: String) throws -> String {
        guard let model else {
            throw ReasoningError.modelNotFound
        }
        // Prepare prompt template combining the JD and CV input into one string
        let prompt = """
        Given the following job description and CV, explain if this is a good match and why.
        
        JD:
        \(jd)
        
        CV:
        \(cv)
        
        Explanation:
        """
        // Provide the prompt to the model as input dictionary
        let input = try MLDictionaryFeatureProvider(dictionary: ["text": prompt])
        // Run prediction using the Core ML model
        let output = try model.prediction(from: input)
        // Extract the model's explanation string from the "output" feature key
        guard let explanation = output.featureValue(for: "output")?.stringValue else {
            throw ReasoningError.outputMissing
        }
        return explanation
    }
}
