//
//  GPT2ReasoningTokenizer.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 2/7/25.
//

import Foundation

protocol ReasoningTokenizer {
    func tokenize(_ text: String, maxLength: Int) throws -> [Int]
}

final class GPT2ReasoningTokenizer: ReasoningTokenizer {
    private var vocab: [String: Int] = [:]
    private var bpeRanks: [Pair: Int] = [:]
    private let padToken: String
    private let vocabFile: String
    private let mergesFile: String
    private let bundle: Bundle

    private struct Pair: Hashable {
        let first: String
        let second: String
    }

    init(
        vocabFile: String = "GPT2Vocab",
        mergesFile: String = "GPT2Merges",
        padToken: String = "<|endoftext|>",
        bundle: Bundle = .main
    ) {
        self.vocabFile = vocabFile
        self.mergesFile = mergesFile
        self.padToken = padToken
        self.bundle = bundle
    }

    func tokenize(_ text: String, maxLength: Int) throws -> [Int] {
        if vocab.isEmpty {
            vocab = try JSONLoader.loadVocab(from: vocabFile, bundle: bundle)
        }
        if bpeRanks.isEmpty {
            let merges = try JSONLoader.loadMerges(from: mergesFile, bundle: bundle)
            bpeRanks = Dictionary(uniqueKeysWithValues: merges.enumerated().map { (index, pair) in
                (Pair(first: pair.0, second: pair.1), index)
            })
        }
        let words = basicEncode(text)
        var ids: [Int] = []
        for word in words {
            let tokens = bpe(word: word)
            for token in tokens {
                ids.append(vocab[token] ?? (vocab[padToken] ?? 50256))
            }
        }
        if ids.count < maxLength {
            let padID = vocab[padToken] ?? 50256
            ids += Array(repeating: padID, count: maxLength - ids.count)
        } else if ids.count > maxLength {
            ids = Array(ids.prefix(maxLength))
        }
        return ids
    }

    private func basicEncode(_ text: String) -> [String] {
        var result: [String] = []
        for byte in text.utf8 {
            let scalar = UnicodeScalar(byte)
            result.append(String(scalar))
        }
        return [result.joined()]
    }

    private func bpe(word: String) -> [String] {
        var chars = word.map { String($0) }
        var pairs = getPairs(chars)
        while true {
            guard
                let minPair = pairs
                    .min(by: { (bpeRanks[$0] ?? Int.max) < (bpeRanks[$1] ?? Int.max) }),
                bpeRanks[minPair] != nil
            else {
                break
            }
            var i = 0
            var newChars: [String] = []
            while i < chars.count {
                if i < chars.count - 1 && chars[i] == minPair.first &&
                    chars[i + 1] == minPair.second {
                    newChars.append(chars[i] + chars[i + 1])
                    i += 2
                } else {
                    newChars.append(chars[i])
                    i += 1
                }
            }
            chars = newChars
            pairs = getPairs(chars)
        }
        return chars
    }

    private func getPairs(_ chars: [String]) -> Set<Pair> {
        var pairs = Set<Pair>()
        for i in 0..<(chars.count - 1) {
            pairs.insert(Pair(first: chars[i], second: chars[i + 1]))
        }
        return pairs
    }
}
