//
//  EmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import CoreML

/// Embedding service protocol for converting input text into vector representation.
protocol EmbeddingService {
    /// Loads the Core ML model from the bundle.
    func loadModel() throws
    /// Converts a given string into an embedding vector.
    func embed(_ text: String) throws -> [Double]
}

/// Errors that can occur during embedding process.
enum EmbeddingError: Error, LocalizedError {
    case modelNotFound            // Model file not found in bundle
    case predictionFailed         // Model failed to run prediction
    case invalidOutput            // Output is missing or not in expected format

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

/// Concrete implementation of EmbeddingService using a Core ML `.mlmodelc` model.
final class CoreMLEmbeddingService: EmbeddingService {
    private var model: MLModel?              // Loaded MLModel instance
    private let modelName: String            // Name of the model file
    private let bundle: Bundle               // Bundle to search for the model

    /// Initializes the service with model name and bundle.
    init(modelName: String = "EmbeddingModel", bundle: Bundle = .main) {
        self.modelName = modelName
        self.bundle = bundle
    }

    /// Loads the compiled Core ML model (.mlmodelc) from the specified bundle.
    func loadModel() throws {
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw EmbeddingError.modelNotFound
        }
        let config = MLModelConfiguration()
        model = try MLModel(contentsOf: url, configuration: config)
    }

    /// Converts the input text into a vector by running it through the Core ML model.
    func embed(_ text: String) throws -> [Double] {
        guard let model else {
            throw EmbeddingError.modelNotFound
        }
        // Prepare input dictionary with the required "text" key expected by the ML model
        let input = try MLDictionaryFeatureProvider(dictionary: ["text": text])
        // Perform prediction using Core ML model and get output feature values
        let output = try model.prediction(from: input)
        guard let embedding = output.featureValue(for: "embedding")?.multiArrayValue else {
            throw EmbeddingError.invalidOutput
        }
        // Convert MLMultiArray to [Double]
        return (0..<embedding.count).map { Double(truncating: embedding[$0]) }
    }
}
