//
//  TokenBasedLLMService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 7/7/25.
//

import Foundation
import Models
import Tokenizers
import Generation
import CoreML

final class TokenBasedLLMService: LLMService {
    private let modelName: String
    private let bundle: Bundle
    private let topK: Int
    private let maxNewTokens:Int
    private var tokenizer: Tokenizer?
    private var languageModel: LanguageModel?
    private var seqLen = 64
    private lazy var input_ids_array = MLMultiArray()
    private lazy var attention_mask_array = MLMultiArray()

    var onPartialOuput: ((String) -> Void)?

    init(modelName: String, bundle: Bundle = .main, topK: Int = 50, maxNewTokens: Int = 60) {
        self.modelName = modelName
        self.bundle = bundle
        self.topK = topK
        self.maxNewTokens = maxNewTokens
    }

    func loadModel() async throws {
        guard let url = bundle.url(forResource: modelName, withExtension: ".mlmodelc") else {
            throw LLMError.modelNotFound
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        let model = try MLModel(contentsOf: url, configuration: configuration)
        let languageModel = LanguageModel(model: model)
        self.languageModel = languageModel
        guard let tokenizerConfig = try await languageModel.tokenizerConfig else {
            throw LLMError.tokenizerNotFound
        }
        tokenizer = try await AutoTokenizer.from(
            tokenizerConfig: tokenizerConfig,
            tokenizerData: languageModel.tokenizerData
        )
        seqLen = model.seqLen ?? 64
        print("----------------------------------------------------")
        print(" ⚡️ Tokenizer: \(String(describing: tokenizer.self))")
        print("----------------------------------------------------\n\n")
    }

    func generateResponse(for prompt: String) async throws -> String {
        guard let tokenizer else {
            throw LLMError.tokenizerNotFound
        }
        print("----------------------------------------------------")
        print(" ⚡️ Prompt: \(prompt)")
        print("----------------------------------------------------\n\n")
        input_ids_array = try MLMultiArray(shape: [1, seqLen] as [NSNumber], dataType: .int32)
        attention_mask_array = try MLMultiArray(shape: [1, seqLen] as [NSNumber], dataType: .int32)
        return try await withTimeout { [weak self] in
            guard let self else {
                throw LLMError.invalidOutput
            }
            var tokens = tokenizer.encode(text: prompt)
            var newTokens = [Int]()
            for i in 0..<maxNewTokens {
                if Task.isCancelled {
                    print("🛑 Task was cancelled in \(Self.self)")
                }
                try Task.checkCancellation()
                let (nextToken, time) = try Utils.time {
                    return try self.predictNextToken(from: tokens)
                }
                tokens.append(nextToken)
                newTokens.append(nextToken)
                let prediction = try decode(tokens: newTokens)
                print("----------------------------------------------------")
                print("🦄 <\(time)s>", i, nextToken, tokens.count)
                print("🦄 Prediction: \(prediction)")
                print("----------------------------------------------------\n\n")
                onPartialOuput?(prediction)
            }
            return try decode(tokens: newTokens)
        }
    }

    private func predictNextToken(from tokens: [Int]) throws -> Int {
        guard let languageModel else {
            throw LLMError.modelNotFound
        }
        guard let tokenizer else {
            throw LLMError.tokenizerNotFound
        }
        let truncated = tokens.suffix(seqLen)
        let padded = Array(truncated) +
        Array(repeating: tokenizer.eosTokenId ?? 0, count: seqLen - truncated.count)
        let attentionValues = padded.map { $0 == (tokenizer.eosTokenId ?? 0) ? 0 : 1 }
        // ⚡️ Reuse buffer
        let inputPtr = UnsafeMutablePointer<Int32>(OpaquePointer(input_ids_array.dataPointer))
        let maskPtr = UnsafeMutablePointer<Int32>(OpaquePointer(attention_mask_array.dataPointer))
        for i in 0..<seqLen {
            inputPtr[i] = Int32(padded[i])
            maskPtr[i] = Int32(attentionValues[i])
        }
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": input_ids_array,
            "attention_mask": attention_mask_array
        ])
        let output = try languageModel.model.prediction(from: provider)
        guard let outputLogits = output.featureValue(for: "logits")?.multiArrayValue else {
            throw LLMError.invalidOutput
        }
        let logitsSlice = MLMultiArray.slice(
            outputLogits,
            indexing: [.select(0), .select(truncated.count - 1), .slice]
        )
        let logits = MLMultiArray.toDoubleArray(logitsSlice)
        let top = Math.topK(arr: logits, k: topK)
        return Math.sample(indexes: top.indexes, probs: top.probs)
    }

    private func decode(tokens: [Int]) throws -> String {
        guard let tokenizer else {
            throw LLMError.tokenizerNotFound
        }
        return tokenizer.decode(tokens: tokens).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension MLModel {
    var seqLen: Int? {
        modelDescription
            .inputDescriptionsByName["input_ids"]?
            .multiArrayConstraint?
            .shape
            .last?
            .intValue
    }
}

extension TokenBasedLLMService {
    static var llama_2_7b_chat: LLMService {
        TokenBasedLLMService(modelName: "llama-2-7b-chat")
    }

    static var tiny_llama: LLMService {
        TokenBasedLLMService(modelName: "tiny-llama", maxNewTokens: 120)
    }
}
