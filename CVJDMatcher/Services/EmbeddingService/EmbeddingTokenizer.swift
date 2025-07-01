//
//  Tokenizer.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 1/7/25.
//

import Foundation

/// Protocol for tokenizing text before feeding into EmbeddingService.
/// Converts raw string into input IDs + attention mask as expected by embedding model.
protocol EmbeddingTokenizer {
    /// Tokenizes input string for use in embedding models (e.g., MiniLM).
    /// - Parameters:
    ///   - text: The input string (CV, JD, etc.)
    ///   - maxLength: Desired sequence length (padding/truncation applied)
    /// - Returns: A tuple of input IDs and attention mask
    func tokenize(_ text: String, maxLength: Int) throws -> (inputIDs: [Int], attentionMask: [Int])
}

/// MiniLM-compatible tokenizer using fixed vocab dictionary (from HuggingFace).
/// Performs basic whitespace-based tokenization with [CLS], [SEP], [PAD], [UNK] support.
final class MiniLMEmbeddingTokenizer: EmbeddingTokenizer {
    private var vocab = [String: Int]()
    private let vocabFile: String
    private let bundle: Bundle
    // Special tokens used by HuggingFace MiniLM
    private let clsToken = "[CLS]"
    private let sepToken = "[SEP]"
    private let unkToken = "[UNK]"
    private let padToken = "[PAD]"

    /// Initializes the tokenizer by loading vocab from a JSON file in the bundle.
    /// - Parameter vocabFile: The filename (without `.json`) of the vocab file.
    /// - Throws: JSONLoaderError if loading or decoding fails.
    init(vocabFile: String = "MiniLMVocab", bundle: Bundle = .main) {
        self.vocabFile = vocabFile
        self.bundle = bundle
    }

    func tokenize(
        _ text: String,
        maxLength: Int
    ) throws -> (inputIDs: [Int], attentionMask: [Int]) {
        if vocab.isEmpty {
            vocab = try JSONLoader.loadVocab(from: vocabFile, bundle: bundle)
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
