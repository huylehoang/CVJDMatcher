//
//  MiniLMEmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 6/7/25.
//

import CoreML

final class MiniLMEmbeddingService: EmbeddingService {
    private typealias Pipeline = CoreMLPipeline<CoreMLTokenInput, CoreMLTokenOutput>

    private var modelName: String
    private let vocabName: String
    private let bundle: Bundle
    private let maxLength: Int
    private var pipeline: Pipeline?
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
        pipeline = try Pipeline(modelName: modelName, bundle: bundle)
        vocab = try VocabLoader.load(vocabName: vocabName, bundle: bundle)
    }

    /// Runs the Core ML model on the input text and returns the embedding vector.
    func embed(_ text: String) throws -> [Float] {
        guard let pipeline else {
            throw AppError.modelNotFound
        }
        let (inputIDs, attentionMask) = tokenize(text)
        let input = CoreMLTokenInput(
            inputIDs: MLMultiArray.from(inputIDs, dims: 2),
            attentionMask: MLMultiArray.from(attentionMask, dims: 2)
        )
        let output = try pipeline.predict(input: input)
        let embeddings = output.logits
        return (0..<embeddings.count).map { Float(truncating: embeddings[$0]) }
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
