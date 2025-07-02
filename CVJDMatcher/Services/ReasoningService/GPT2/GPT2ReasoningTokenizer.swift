//
//  GPT2ReasoningTokenizer.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 2/7/25.
//

import CoreML

final class GPT2ReasoningTokenizer: ReasoningTokenizer {
    private struct Pair: Hashable {
        let first: String
        let second: String
    }

    private let filename: String
    private let bundle: Bundle
    private let maxTokens: Int
    private var model: GPT2TokenizerModel?
    private var vocab: [String: Int]?
    private var idToToken: [Int: String]?
    private var bpeRanks: [Pair: Int]?
    private var eosTokenID: Int

    init(
        filename: String = "gpt2_tokenizer",
        bundle: Bundle = .main,
        maxTokens: Int = 64,
        eosTokenID: Int = 50256
    ) {
        self.filename = filename
        self.bundle = bundle
        self.maxTokens = maxTokens
        self.eosTokenID = eosTokenID
    }

    func encode(_ text: String, maxLength: Int) throws -> MLMultiArray {
        try loadModelIfNeeded()
        guard let vocab = vocab else {
            throw ReasoningError.invalidInput
        }
        let byteEncoded = byteLevelEncode(text)
        var ids: [Int] = []
        for word in byteEncoded {
            let tokens = bpe(word: word)
            for token in tokens {
                ids.append(vocab[token] ?? eosTokenID)
            }
        }
        if ids.count < maxLength {
            ids += Array(repeating: eosTokenID, count: maxLength - ids.count)
        } else if ids.count > maxLength {
            ids = Array(ids.prefix(maxLength))
        }
        return try MLMultiArrayUtils.int32(from: ids, shape: [1, maxLength])
    }

    func decode(from logits: MLMultiArray) throws -> String {
        try loadModelIfNeeded()
        guard let idToToken = idToToken else {
            throw ReasoningError.invalidInput
        }
        guard logits.shape.count == 3,
              logits.shape[0].intValue == 1 else {
            throw ReasoningError.invalidOutput
        }
        let sequenceLength = logits.shape[1].intValue
        let vocabSize = logits.shape[2].intValue
        var tokenStrings: [String] = []
        let temperature: Double = 1.0
        let topK: Int = 50
        for t in 0..<min(sequenceLength, maxTokens) {
            var logitsAtStep: [(Int, Double)] = []
            for v in 0..<vocabSize {
                let index = [0, t, v].map { NSNumber(value: $0) }
                let rawLogit = logits[index].doubleValue
                let adjusted = rawLogit / temperature
                logitsAtStep.append((v, adjusted))
            }

            // Sort by logit descending and keep topK
            let topKSorted = logitsAtStep.sorted(by: { $0.1 > $1.1 }).prefix(topK)
            let maxLogit = topKSorted.map { $0.1 }.max() ?? 0
            let expScores = topKSorted.map { exp($0.1 - maxLogit) }
            let sumExp = expScores.reduce(0, +)

            // Sample from topK using softmax distribution
            let probabilities = expScores.map { $0 / sumExp }
            let sampledIndex = sampleIndex(probabilities)
            let sampledTokenID = topKSorted[sampledIndex].0
            if sampledTokenID == eosTokenID {
                break
            }
            let token = idToToken[sampledTokenID] ?? ""
            tokenStrings.append(token)
        }
        let joined = tokenStrings.joined()
        return byteLevelDecode(joined)
    }

    private func sampleIndex(_ probabilities: [Double]) -> Int {
        let cumulative = probabilities.reduce(into: [Double]()) { result, p in
            result.append((result.last ?? 0) + p)
        }
        let rand = Double.random(in: 0..<1)
        for (i, value) in cumulative.enumerated() {
            if rand < value {
                return i
            }
        }
        return probabilities.indices.last ?? 0
    }

    private func loadModelIfNeeded() throws {
        if model == nil {
            model = try JSONLoader.loadModel(
                from: filename,
                as: GPT2TokenizerModel.self,
                bundle: bundle
            )
        }
        if vocab == nil, let vocabMap = model?.model.vocab {
            vocab = vocabMap
        }
        if idToToken == nil, let vocab = vocab {
            idToToken = Dictionary(uniqueKeysWithValues: vocab.map { ($1, $0) })
        }
        if bpeRanks == nil, let merges = model?.model.merges {
            bpeRanks = Dictionary(uniqueKeysWithValues: merges.enumerated().map {
                (Pair(first: $1[0], second: $1[1]), $0)
            })
        }
    }

    // MARK: - Byte-Level Encoding & Decoding

    private func byteLevelEncode(_ text: String) -> [String] {
        var encoded: [String] = []
        for byte in text.utf8 {
            if let scalar = byteToUnicode[Int(byte)] {
                encoded.append(String(scalar))
            }
        }
        return [encoded.joined()]
    }

    private func byteLevelDecode(_ text: String) -> String {
        var bytes: [UInt8] = []
        for scalar in text.unicodeScalars {
            if let byte = unicodeToByte[scalar] {
                bytes.append(byte)
            }
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    // MARK: - BPE

    private func bpe(word: String) -> [String] {
        guard let bpeRanks = bpeRanks else { return [word] }
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
                if i < chars.count - 1 && chars[i] == minPair.first && chars[i + 1] == minPair.second {
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

    // MARK: - Byte-Level Maps

    private lazy var byteToUnicode: [Int: UnicodeScalar] = {
        var byteToUnicode = [Int: UnicodeScalar]()
        var bs = [Int]()
        bs.append(contentsOf: (33...126))
        bs.append(contentsOf: (161...172))
        bs.append(contentsOf: (174...255))
        var cs = bs
        var n = 0
        for b in 0..<256 {
            if !bs.contains(b) {
                bs.append(b)
                cs.append(256 + n)
                n += 1
            }
        }
        for (b, c) in zip(bs, cs) {
            byteToUnicode[b] = UnicodeScalar(c)!
        }
        return byteToUnicode
    }()

    private lazy var unicodeToByte: [UnicodeScalar: UInt8] = {
        var map = [UnicodeScalar: UInt8]()
        for (b, u) in byteToUnicode {
            map[u] = UInt8(b)
        }
        return map
    }()
}
