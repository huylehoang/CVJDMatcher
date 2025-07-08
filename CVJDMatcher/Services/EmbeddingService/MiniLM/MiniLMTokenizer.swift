//
//  MiniLMTokenizer.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 6/7/25.
//

import Foundation

protocol MiniLMTokenizerInterface {
    func tokenize(_ text: String, maxLength: Int) throws -> (inputIDs: [Int], attentionMask: [Int])
}

final class MiniLMTokenizer: MiniLMTokenizerInterface {
    private var vocab = [String: Int]()
    private let vocabFile: String
    private let bundle: Bundle
    // Special tokens used by HuggingFace MiniLM
    private let clsToken = "[CLS]"
    private let sepToken = "[SEP]"
    private let unkToken = "[UNK]"
    private let padToken = "[PAD]"

    init(vocabFile: String = "mini_lm_vocab", bundle: Bundle = .main) {
        self.vocabFile = vocabFile
        self.bundle = bundle
    }

    func tokenize(
        _ text: String,
        maxLength: Int
    ) throws -> (inputIDs: [Int], attentionMask: [Int]) {
        if vocab.isEmpty {
            vocab = try JSONLoader.loadJson(from: vocabFile, bundle: bundle)
        }
        // 1. Whitespace split and lowercase
        let tokens = text.lowercased().split(separator: " ").map(String.init)
        // 2. Begin with CLS
        var tokenIDs: [Int] = [vocab[clsToken] ?? 101]
        // 3. Convert tokens or use UNK fallback
        tokenIDs += tokens.map { vocab[$0] ?? vocab[unkToken] ?? 100 }
        // 4. End with SEP
        tokenIDs.append(vocab[sepToken] ?? 102)
        // 5. Pad/truncate
        let padId = vocab[padToken] ?? 0
        if tokenIDs.count < maxLength {
            tokenIDs += Array(repeating: padId, count: maxLength - tokenIDs.count)
        } else if tokenIDs.count > maxLength {
            tokenIDs = Array(tokenIDs.prefix(maxLength))
        }
        // 6. Attention mask (1 = token, 0 = pad)
        let attentionMask = tokenIDs.map { $0 == padId ? 0 : 1 }
        return (tokenIDs, attentionMask)
    }
}
