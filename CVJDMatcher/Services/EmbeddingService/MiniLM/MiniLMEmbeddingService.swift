//
//  MiniLMEmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 6/7/25.
//

import CoreML

final class MiniLMEmbeddingService: EmbeddingService {
    private var model: EmbeddingModel?
    private let tokenizer: MiniLMTokenizerInterface
    private let maxLength: Int

    /// Creates a new embedding service instance.
    init(
        tokenizer: MiniLMTokenizerInterface = MiniLMTokenizer(),
        maxLength: Int = 128
    ) {
        self.tokenizer = tokenizer
        self.maxLength = maxLength
    }

    /// Loads the compiled Core ML model from the app bundle.
    func loadModel() async throws {
        model = try await EmbeddingModel.load()
    }

    /// Runs the Core ML model on the input text and returns the embedding vector.
    func embed(_ text: String) throws -> [Double] {
        guard let model else {
            throw EmbeddingError.modelNotFound
        }
        // Tokenize text → [input_ids], [attention_mask]
        let input = try tokenizer.tokenize(text, maxLength: maxLength)
        // Convert token arrays to MLMultiArray
        let inputIDs = MLMultiArray.from(input.inputIDs, dims: 2)
        let attentionMask = MLMultiArray.from(input.attentionMask, dims: 2)
        // Perform inference using the Core ML model
        let output = try model.prediction(input_ids: inputIDs, attention_mask: attentionMask)
        let embedding = output.var_501
        // Extract and convert output to [Double]
        return (0..<embedding.count).map { Double(truncating: embedding[$0]) }
    }
}
