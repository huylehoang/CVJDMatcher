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

    func loadModel() async throws {
        model = try await llama_2_7b_chat.load()
        let languageModel = LanguageModel(model: model.model)
        tokenizer = try await AutoTokenizer.from(
            tokenizerConfig: languageModel.tokenizerConfig!,
            tokenizerData: languageModel.tokenizerData
        )
        model.model.configuration.computeUnits = .all
        if let dims = model
            .model
            .modelDescription
            .inputDescriptionsByName["input_ids"]?
            .multiArrayConstraint?
            .shape,
           let n = dims.last?.intValue {
            seqLen = n
        }
    }

    func explain(jd: String, cv: String) throws -> String {
        let prompt = makePrompt2(jd: jd, cv: cv)
        var tokens = tokenizer.encode(text: prompt)
        var newTokens = [Int]()
        for i in 0..<maxNewTokens {
            let (nextToken, time) = Utils.time {
                return predictNextToken(from: tokens)
            }
            if nextToken == tokenizer.eosTokenId {
                print("----------------------------------------------------")
                print("✋ <\(time)s>: stop early due to eos", i, nextToken, tokens.count)
                print("----------------------------------------------------\n\n")
                break
            }
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

    func decode(tokens: [Int]) -> String {
        tokenizer.decode(tokens: tokens).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeSimplePrompt(jd: String, cv: String) -> String {
        """
        [INST] <<SYS>>
        You are a job match assistant.
        Respond in format:
        Match: Yes/No
        Reason: (concise explanation)
        <</SYS>>
        Job Description: \(jd)
        Candidate CV: \(cv)
        [/INST]
        Match:
        """
    }

    private func makePrompt(jd: String, cv: String) -> String {
        """
        [INST] <<SYS>>
        You are an AI assistant that evaluates whether a candidate matches a job description.
        
        ALWAYS reply using **only this format**:
        Match: Yes or No  
        Reason: <short explanation of why they match or not (1–2 sentences)>
        
        Do not add anything else. No introductions. No extra text. Only output in that format.
        <</SYS>>
        
        Job: Looking for iOS Developer with Swift, Combine  
        CV: Nguyen A: Senior iOS Developer with Swift and MVVM  
        Match: Yes
        Reason: Candidate has strong iOS experience and Swift; \
        MVVM indicates architecture knowledge. Combine is learnable.
        
        Job: Backend Developer with Node.js, PostgreSQL  
        CV: Jenny B: Frontend Developer with React, TailwindCSS  
        Match: No
        Reason: No backend or database experience in CV.
        
        Job: \(jd)  
        CV: \(cv)  
        Match:
        Reason:
        [/INST]
        """
    }

    private func makePrompt2(jd: String, cv: String) -> String {
        """
        You are an AI model that determines whether a job description and a candidate CV match.
        
        Respond strictly using:
        Match: Match or Not Match  
        Reason: 1–2 concise sentences explaining the match decision.
        
        Do NOT write anything else. No introductions. No summaries.
        
        === Example 1 ===
        Job: Looking for iOS Developer with Swift, Combine  
        CV: Nguyen A: Senior iOS Developer with Swift and MVVM  
        Match: Match  
        Reason: Strong iOS and Swift experience; MVVM shows architecture knowledge; \
        Combine is learnable.
        
        === Example 2 ===
        Job: Backend Developer with Node.js, MongoDB  
        CV: Jenny B: Frontend Developer with React, TailwindCSS  
        Match: Not Match  
        Reason: Candidate has no backend experience in the required stack.
        
        === Now evaluate ===
        Job: \(jd)
        CV: \(cv)
        Match:
        """
    }

    private func legacyPredictNextToken(from tokens: [Int]) -> Int {
        let truncated = tokens.suffix(seqLen)
        let padded = Array(truncated) +
        Array(repeating: tokenizer.eosTokenId ?? 0, count: seqLen - truncated.count)
        let input_ids = MLMultiArray.from(padded, dims: 2)
        let attentionValues = padded.map { $0 == (tokenizer.eosTokenId ?? 0) ? 0 : 1 }
        let attention_mask = MLMultiArray.from(attentionValues, dims: 2)
        let output = try! model.prediction(input_ids: input_ids, attention_mask: attention_mask)
        let logitsSlice = MLMultiArray.slice(
            output.logits,
            indexing: [.select(0), .select(truncated.count - 1), .slice]
        )
        let logits = MLMultiArray.toDoubleArray(logitsSlice)
        let top = Math.topK(arr: logits, k: topK)
        return Math.sample(indexes: top.indexes, probs: top.probs)
    }
}
