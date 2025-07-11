//
//  Llama2ReasoningService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 7/7/25.
//

import Foundation
import Models
import Tokenizers
import Generation
import CoreML

final class Llama2ReasoningService: ReasoningService {
    private var tokenizer: Tokenizer!
    private var model: llama_2_7b_chat!
    private var seqLen = 64
    private let topK = 50
    private let maxNewTokens = 60

    var onPartialExplanation: ((String) -> Void)?

    var constructPrompt: ConstructPrompt = { jd, cv in
        """
        You are an AI model helping match Job Descriptions (JD) with Candidate CVs.

        Respond in **exactly this format** and focus **only on the technical match**:
        Job: <copied JD>
        CV: <copied CV>
        Match: Yes | No
        Reason: <1-2 short technical reasons why they match or not>

        Do not write anything outside of this format. No summaries, no greetings.

        === Format Example ===
        Job: Looking for iOS Developer with Swift, Combine
        CV: Nguyen A: Senior iOS Developer with Swift and MVVM
        Match: Yes
        Reason: Strong iOS and Swift experience; MVVM shows architecture knowledge; \
        Combine is learnable.

        === Another Example ===
        Job: Backend Developer with Node.js, MongoDB
        CV: Jenny B: Frontend Developer with React, TailwindCSS
        Match: No
        Reason: Candidate lacks backend or Node.js experience.

        === Now Evaluate ===
        Job: \(jd)
        CV: \(cv)
        """
    }

    func loadModel() async throws {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        model = try await llama_2_7b_chat.load(configuration: configuration)
        let languageModel = LanguageModel(model: model.model)
        tokenizer = try await AutoTokenizer.from(
            tokenizerConfig: languageModel.tokenizerConfig!,
            tokenizerData: languageModel.tokenizerData
        )
        if let dims = model
            .model
            .modelDescription
            .inputDescriptionsByName["input_ids"]?
            .multiArrayConstraint?
            .shape,
           let n = dims.last?.intValue {
            seqLen = n
        }
        print("----------------------------------------------------")
        print(" ⚡️ Tokenizer: \(String(describing: tokenizer.self))")
        print("----------------------------------------------------\n\n")
    }

    func explain(jd: String, cv: String) async throws -> String {
        let prompt = constructPrompt(jd, cv)
        print("----------------------------------------------------")
        print(" ⚡️ Prompt: \(prompt)")
        print("----------------------------------------------------\n\n")
        var tokens = tokenizer.encode(text: prompt)
        var newTokens = [Int]()
        for i in 0..<maxNewTokens {
            let (nextToken, time) = Utils.time {
                return predictNextToken(from: tokens)
            }
//            if nextToken == tokenizer.eosTokenId {
//                print("----------------------------------------------------")
//                print("✋ <\(time)s>: stop early due to eos", i, nextToken, tokens.count)
//                print("----------------------------------------------------\n\n")
//                break
//            }
            tokens.append(nextToken)
            newTokens.append(nextToken)
            let prediction = decode(tokens: newTokens)
            print("----------------------------------------------------")
            print("🦄 <\(time)s>", i, nextToken, tokens.count)
            print("🦄 Prediction: \(prediction)")
            print("----------------------------------------------------\n\n")
            onPartialExplanation?(prediction)
        }
        return decode(tokens: newTokens)
    }

    private lazy var input_ids_array: MLMultiArray = {
        try! MLMultiArray(shape: [1, seqLen] as [NSNumber], dataType: .int32)
    }()

    private lazy var attention_mask_array: MLMultiArray = {
        try! MLMultiArray(shape: [1, seqLen] as [NSNumber], dataType: .int32)
    }()

    private func predictNextToken(from tokens: [Int]) -> Int {
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
        let output = try! model.prediction(
            input_ids: input_ids_array,
            attention_mask: attention_mask_array
        )
        let logitsSlice = MLMultiArray.slice(
            output.logits,
            indexing: [.select(0), .select(truncated.count - 1), .slice]
        )
        let logits = MLMultiArray.toDoubleArray(logitsSlice)
        let top = Math.topK(arr: logits, k: topK)
        return Math.sample(indexes: top.indexes, probs: top.probs)
    }

    private func decode(tokens: [Int]) -> String {
        tokenizer.decode(tokens: tokens).trimmingCharacters(in: .whitespacesAndNewlines)
    }

//    private func legacyPredictNextToken(from tokens: [Int]) -> Int {
//        let truncated = tokens.suffix(seqLen)
//        let padded = Array(truncated) +
//        Array(repeating: tokenizer.eosTokenId ?? 0, count: seqLen - truncated.count)
//        let input_ids = MLMultiArray.from(padded, dims: 2)
//        let attentionValues = padded.map { $0 == (tokenizer.eosTokenId ?? 0) ? 0 : 1 }
//        let attention_mask = MLMultiArray.from(attentionValues, dims: 2)
//        let output = try! model.prediction(input_ids: input_ids, attention_mask: attention_mask)
//        let logitsSlice = MLMultiArray.slice(
//            output.logits,
//            indexing: [.select(0), .select(truncated.count - 1), .slice]
//        )
//        let logits = MLMultiArray.toDoubleArray(logitsSlice)
//        let top = Math.topK(arr: logits, k: topK)
//        return Math.sample(indexes: top.indexes, probs: top.probs)
//    }
}
