//
//  GPT2ReasoningDecoder.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 1/7/25.
//

import Foundation
import CoreML

// MARK: - Protocol
protocol ReasoningDecoder {
    func decode(from logits: MLMultiArray) throws -> String
}

// MARK: - GPT2 Reasoning Decoder
final class GPT2ReasoningDecoder: ReasoningDecoder {
    private let vocabFile: String
    private let bundle: Bundle
    private let maxTokens: Int
    private let eosTokenID: Int
    private var idToToken: [Int: String] = [:]

    init(
        vocabFile: String = "GPT2Vocab",
        bundle: Bundle = .main,
        maxTokens: Int = 64,
        eosTokenID: Int = 50256
    ) {
        self.vocabFile = vocabFile
        self.bundle = bundle
        self.maxTokens = maxTokens
        self.eosTokenID = eosTokenID
    }

    func decode(from logits: MLMultiArray) throws -> String {
        // Lazy-load vocab
        if idToToken.isEmpty {
            let tokenToID = try JSONLoader.loadVocab(from: vocabFile, bundle: bundle)
            idToToken = Dictionary(uniqueKeysWithValues: tokenToID.map { ($1, $0) })
        }
        guard logits.shape.count == 3,
              logits.shape[0].intValue == 1 else {
            throw ReasoningError.invalidOutput
        }
        let sequenceLength = logits.shape[1].intValue
        let vocabSize = logits.shape[2].intValue
        var tokenStrings: [String] = []
        for t in 0..<min(sequenceLength, maxTokens) {
            var bestID = -1
            var bestLogit = -Double.infinity
            for v in 0..<vocabSize {
                let index = [0, t, v].map { NSNumber(value: $0) }
                let logit = logits[index].doubleValue
                if logit > bestLogit {
                    bestLogit = logit
                    bestID = v
                }
            }
            if bestID == eosTokenID {
                break
            }
            let token = idToToken[bestID] ?? ""
            tokenStrings.append(token)
        }
        let rawText = tokenStrings.joined()
        let cleaned = rawText
            .replacingOccurrences(of: "Ġ", with: " ")  // GPT-2 space
            .replacingOccurrences(of: "Â", with: "")   // encoding noise
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
}
