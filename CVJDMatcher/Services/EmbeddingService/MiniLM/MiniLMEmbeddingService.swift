//
//  MiniLMEmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 6/7/25.
//

import CoreML

final class MiniLMEmbeddingService: EmbeddingService {
    private var modelName: String
    private let vocabName: String
    private let bundle: Bundle
    private let maxLength: Int
    private var model: MLModel?
    private var vocab = [String: Int]()
    // Special tokens used by HuggingFace MiniLM
    private let clsToken = "[CLS]"
    private let sepToken = "[SEP]"
    private let unkToken = "[UNK]"
    private let padToken = "[PAD]"

    /// Creates a new embedding service instance.
    init(
        modelName: String = "mini_lm",
        vocabName: String = "mini_lm_vocab",
        bundle: Bundle = .main,
        maxLength: Int = 128
    ) {
        self.modelName = modelName
        self.vocabName = vocabName
        self.bundle = bundle
        self.maxLength = maxLength
    }

    /// Loads the compiled Core ML model from the app bundle.
    func loadModel() async throws {
        guard
            let modelUrl = bundle.url(forResource: modelName, withExtension: ".mlmodelc"),
            let vocabUrl = bundle.url(forResource: vocabName, withExtension: "json")
        else {
            throw EmbeddingError.modelNotFound
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        model = try MLModel(contentsOf: modelUrl, configuration: configuration)
        let data = try Data(contentsOf: vocabUrl)
        vocab = try JSONDecoder().decode([String:Int].self, from: data)
    }

    /// Runs the Core ML model on the input text and returns the embedding vector.
    func embed(_ text: String) throws -> [Float] {
        guard let model else {
            throw EmbeddingError.modelNotFound
        }
        let input = tokenize(text)
        let inputIDs = MLMultiArray.from(input.inputIDs, dims: 2)
        let attentionMask = MLMultiArray.from(input.attentionMask, dims: 2)
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": inputIDs,
            "attention_mask": attentionMask
        ])
        let output = try model.prediction(from: provider)
        guard
            let name = output.featureNames.first,
            let embedding = output.featureValue(for: name)?.multiArrayValue
        else {
            throw EmbeddingError.invalidOutput
        }
        return (0..<embedding.count).map { Float(truncating: embedding[$0]) }
    }

    private func tokenize(_ text: String) -> (inputIDs: [Int], attentionMask: [Int]) {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var tokenIDs: [Int] = [vocab[clsToken] ?? 101]
        for word in words {
            if word.isEmpty {
                continue
            }
            let subwordIDs = tokenizeWordPiece(word)
            tokenIDs.append(contentsOf: subwordIDs)
        }
        tokenIDs.append(vocab[sepToken] ?? 102)
        let padId = vocab[padToken] ?? 0
        if tokenIDs.count < maxLength {
            tokenIDs += Array(repeating: padId, count: maxLength - tokenIDs.count)
        } else if tokenIDs.count > maxLength {
            tokenIDs = Array(tokenIDs.prefix(maxLength))
        }
        let attentionMask = tokenIDs.map { $0 == padId ? 0 : 1 }
        return (tokenIDs, attentionMask)
    }

    private func tokenizeWordPiece(_ word: String) -> [Int] {
        var subTokens = [String]()
        var start = word.startIndex
        while start < word.endIndex {
            var end = word.endIndex
            var found = ""
            while end > start {
                var substr = String(word[start..<end])
                if start != word.startIndex {
                    substr = "##" + substr
                }
                if vocab[substr] != nil {
                    found = substr
                    break
                }
                end = word.index(before: end)
            }
            if found.isEmpty {
                subTokens.append(unkToken)
                break
            }
            subTokens.append(found)
            start = word.index(
                start, offsetBy: found.hasPrefix("##") ? found.count - 2 : found.count
            )
        }
        return subTokens.map { vocab[$0] ?? vocab[unkToken]! }
    }
}
