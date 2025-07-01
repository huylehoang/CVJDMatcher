//
//  EmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import CoreML

/// Protocol defining an embedding service that transforms text into vector representation.
protocol EmbeddingService {
    /// Loads the Core ML model from the app bundle.
    func loadModel() throws
    /// Embeds a text string into a numeric vector using the Core ML model.
    func embed(_ text: String) throws -> [Double]
}

/// Errors that can occur during the embedding process.
enum EmbeddingError: Error, LocalizedError {
    case modelNotFound            // .mlmodelc file not found in bundle
    case predictionFailed         // Model prediction failed
    case invalidOutput            // Model output is missing or malformed

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

/// Implementation of `EmbeddingService` using a Core ML model (.mlmodelc) + injected tokenizer.
final class CoreMLEmbeddingService: EmbeddingService {
    private var model: MLModel?                 // The loaded Core ML model
    private let modelName: String               // File name of the .mlmodelc (without extension)
    private let bundle: Bundle                  // Bundle containing the model
    private let tokenizer: EmbeddingTokenizer   // Tokenizer for converting text to token IDs
    private let maxLength: Int                  // Maximum token length per input

    /// Creates a new embedding service instance.
    init(
        modelName: String = "EmbeddingModel",
        bundle: Bundle = .main,
        tokenizer: EmbeddingTokenizer = MiniLMEmbeddingTokenizer(),
        maxLength: Int = 128
    ) {
        self.modelName = modelName
        self.bundle = bundle
        self.tokenizer = tokenizer
        self.maxLength = maxLength
    }

    /// Loads the compiled Core ML model from the app bundle.
    func loadModel() throws {
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw EmbeddingError.modelNotFound
        }
        let config = MLModelConfiguration()
        model = try MLModel(contentsOf: url, configuration: config)
    }

    /// Runs the Core ML model on the input text and returns the embedding vector.
    func embed(_ text: String) throws -> [Double] {
        guard let model else {
            throw EmbeddingError.modelNotFound
        }
        // Tokenize text → [input_ids], [attention_mask]
        let (inputIDs, attentionMask) = try tokenizer.tokenize(text, maxLength: maxLength)
        // Convert token arrays to MLMultiArray
        let inputIDArray = try MLMultiArrayUtils.int32(from: inputIDs, shape: [1, maxLength])
        let attentionArray = try MLMultiArrayUtils.int32(from: attentionMask, shape: [1, maxLength])
        // Prepare Core ML input dictionary
        let input: [String: Any] = [
            "input_ids": inputIDArray,
            "attention_mask": attentionArray
        ]
        let features = try MLDictionaryFeatureProvider(dictionary: input)
        // Perform inference using the Core ML model
        let output = try model.prediction(from: features)
        // Extract and convert output to [Double]
        guard
            let outputName = model.modelDescription.outputDescriptionsByName.keys.first,
            let embedding = output.featureValue(for: outputName)?.multiArrayValue
        else {
            throw EmbeddingError.invalidOutput
        }
        return (0..<embedding.count).map { Double(truncating: embedding[$0]) }
    }
}
