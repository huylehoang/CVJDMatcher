//
//  GPT2ReasoningService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 7/7/25.
//

import Foundation
import CoreML
import Tokenizers

final class GPT2ReasoningService: ReasoningService {
    private var tokenizer: Tokenizer!
    private var model: gpt2_512!
    private var seqLen = 64
    private let topK: Int = 20
    private let nTokens: Int = 80
    
    func loadModel() async throws {
        tokenizer = try await AutoTokenizer.from(pretrained: "gpt2")
        model = try await gpt2_512.load()
        seqLen = model
            .model
            .modelDescription
            .inputDescriptionsByName["input_ids"]?
            .multiArrayConstraint?
            .shape
            .first?
            .intValue ?? 64 // fallback
    }
    
    func explain(jd: String, cv: String) async throws -> String {
        let prompt = """
        Job Description: \(jd)

        Candidate CV: \(cv)

        Question: Do they match? Answer "Yes" or "No" and one-sentence explanation.

        Answer:
        """
        var tokens = tokenizer.encode(text: prompt)
        var newTokens: [Int] = []
        for i in 0..<nTokens {
            let (nextToken, time) = Utils.time {
                return predict(tokens: tokens)
            }
            tokens.append(nextToken)
            newTokens.append(nextToken)
            print("🦄 <\(time)s>", i, nextToken, tokens.count)

            // ✋
            if nextToken == tokenizer.eosTokenId {
                print("stop early due to eos")
                break
            }
        }
        return tokenizer.decode(tokens: newTokens)
    }

    private func predict(tokens: [Int]) -> Int {
        let maxTokens = (tokens.count > seqLen) ? Array(tokens[..<seqLen]) : tokens
        let input_ids = MLMultiArray.from(
            maxTokens + Array(repeating: 0, count: seqLen - maxTokens.count)
        )
        let position_ids = MLMultiArray.from(
            Array(0..<seqLen)
        )
        let output = try! model.prediction(input_ids: input_ids, position_ids: position_ids)
        let outputLogits = MLMultiArray.slice(
            output.output_logits,
            indexing: [.select(0), .select(maxTokens.count - 1), .slice, .select(0), .select(0)]
        )
        let logits = MLMultiArray.toDoubleArray(outputLogits)
        let topk = Math.topK(arr: logits, k: topK)
        let sampleIndex = Math.sample(indexes: topk.indexes, probs: topk.probs)
        return sampleIndex
    }
}
