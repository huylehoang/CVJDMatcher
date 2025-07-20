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
    private typealias Pipeline = CoreMLPipeline<CoreMLTokenInput, CoreMLTokenOutput>

    private let modelName: String
    private let bundle: Bundle
    private let topK: Int
    private let maxNewTokens:Int
    private let appLogger: AppLogger
    private var tokenizer: Tokenizer?
    private var pipeline: Pipeline?
    private var seqLen = 64
    private var eosTokenId = 0
    private lazy var inputIDs = MLMultiArray()
    private lazy var attentionMask = MLMultiArray()

    var onPartialOuput: ((String) -> Void)?

    init(
        modelName: String,
        bundle: Bundle = .main,
        topK: Int = 50,
        maxNewTokens: Int = 60,
        appLogger: AppLogger = ConsoleAppLogger()
    ) {
        self.modelName = modelName
        self.bundle = bundle
        self.topK = topK
        self.maxNewTokens = maxNewTokens
        self.appLogger = appLogger
    }

    func loadModel() async throws {
        let pipeline = try Pipeline(modelName: modelName, bundle: bundle)
        self.pipeline = pipeline
        let model = pipeline.model
        seqLen = model.seqLen ?? 64
        let languageModel = LanguageModel(model: model)
        guard let tokenizerConfig = try await languageModel.tokenizerConfig else {
            throw AppError.tokenizerNotFound
        }
        tokenizer = try await AutoTokenizer.from(
            tokenizerConfig: tokenizerConfig,
            tokenizerData: languageModel.tokenizerData
        )
        eosTokenId = tokenizer?.eosTokenId ?? 0
        if let tokenizer {
            appLogger.logTokenizer(tokenizer)
        }
    }

    func generateResponse(for prompt: String) async throws -> String {
        guard let tokenizer else {
            throw AppError.tokenizerNotFound
        }
        appLogger.logPrompt(prompt)
        inputIDs = try MLMultiArray(shape: [1, seqLen] as [NSNumber], dataType: .int32)
        attentionMask = try MLMultiArray(shape: [1, seqLen] as [NSNumber], dataType: .int32)
        return try await withTimeout { [weak self] in
            guard let self else {
                throw AppError.invalidOutput
            }
            var tokens = tokenizer.encode(text: prompt)
            var newTokens = [Int]()
            for i in 0..<maxNewTokens {
                try Task.checkCancellation()
                let (nextToken, time) = try Utils.time {
                    return try self.predictNextToken(from: tokens)
                }
                try Task.checkCancellation()
                tokens.append(nextToken)
                newTokens.append(nextToken)
                let prediction = try decode(tokens: newTokens)
                appLogger.logPrediction(prediction, index: i, time: time)
                onPartialOuput?(prediction)
            }
            return try decode(tokens: newTokens)
        }
    }

    private func predictNextToken(from tokens: [Int]) throws -> Int {
        guard let pipeline else {
            throw AppError.modelNotFound
        }
        let truncated = tokens.suffix(seqLen)
        let padded = Array(truncated) +
        Array(repeating: eosTokenId, count: seqLen - truncated.count)
        let attentionValues = padded.map { $0 == eosTokenId ? 0 : 1 }
        // ⚡️ Reuse buffer
        let inputIDsPointer = UnsafeMutablePointer<Int32>(OpaquePointer(inputIDs.dataPointer))
        let attentionMaskPointer = UnsafeMutablePointer<Int32>(
            OpaquePointer(attentionMask.dataPointer)
        )
        for i in 0..<seqLen {
            inputIDsPointer[i] = Int32(padded[i])
            attentionMaskPointer[i] = Int32(attentionValues[i])
        }
        let input = CoreMLTokenInput(inputIDs: inputIDs, attentionMask: attentionMask)
        let output = try pipeline.predict(input: input)
        let outputLogits = output.logits
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
            throw AppError.tokenizerNotFound
        }
        return tokenizer.decode(tokens: tokens)
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
        TokenBasedLLMService(modelName: "tiny_llama", maxNewTokens: 512)
    }
}
