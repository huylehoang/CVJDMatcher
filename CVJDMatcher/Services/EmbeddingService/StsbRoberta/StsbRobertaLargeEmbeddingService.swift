//
//  StsbRobertaLargeEmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 12/7/25.
//

import CoreML

final class StsbRobertaLargeEmbeddingService: EmbeddingService {
    private typealias Pipeline = CoreMLPipeline<CoreMLTokenInput, CoreMLTokenOutput>

    private let modelName: String
    private let vocabName: String
    private let bundle: Bundle
    private let maxLength: Int
    private var pipeline: Pipeline?
    private var vocab = [String: Int]()

    init(
        modelName: String = "stsb_roberta_large",
        vocabName: String = "stsb_roberta_large_vocab",
        bundle: Bundle = .main,
        maxLength: Int = 128
    ) {
        self.modelName = modelName
        self.vocabName = vocabName
        self.bundle = bundle
        self.maxLength = maxLength
    }

    func loadModel() async throws {
        pipeline = try Pipeline(modelName: modelName, bundle: bundle)
        vocab = try VocabLoader.load(vocabName: vocabName, bundle: bundle)
    }

    func embed(_ text: String) throws -> [Float] {
        guard let pipeline else {
            throw AppError.modelNotFound
        }
        let (inputIDs, attentionMask) = tokenize(text)
        let input = CoreMLTokenInput(
            inputIDs: MLMultiArray.from(inputIDs, dims: 2),
            attentionMask: MLMultiArray.from(attentionMask, dims: 2)
        )
        let output = try pipeline.predict(input: input)
        let embeddings = output.logits
        return (0..<embeddings.count).map { Float(truncating: embeddings[$0]) }
    }

    private func tokenize(_ text: String) -> ([Int],[Int]) {
        let tokens = wordPiece(_word: text.lowercased())
        let cls = vocab["<s>"]!, sep = vocab["</s>"]!
        var ids = [cls] + tokens + [sep]
        let padId = vocab["<pad>"] ?? 1
        if ids.count < maxLength {
            ids += Array(repeating: padId, count: maxLength - ids.count)
        } else {
            ids = Array(ids.prefix(maxLength))
        }
        let mask = ids.map { $0 == padId ? 0 : 1 }
        return (ids, mask)
    }

    private func wordPiece(_word: String) -> [Int] {
        // Simplified greedy algorithm using whitespace + prefix "##"
        var results: [Int] = []
        let parts = _word
            .split(whereSeparator: { $0.isWhitespace })
            .flatMap { greedySubwords(for: String($0)) }
        for token in parts {
            results.append(vocab[token] ?? vocab["<unk>"]!)
        }
        return results
    }

    private func greedySubwords(for word: String) -> [String] {
        var subTokens: [String] = []
        var start = word.startIndex
        while start < word.endIndex {
            var end = word.endIndex
            var match: String?
            while end > start {
                let substr = String(word[start..<end])
                let candidate = (start == word.startIndex) ? substr : "##"+substr
                if vocab[candidate] != nil {
                    match = candidate
                    break
                }
                end = word.index(before: end)
            }
            guard let found = match else {
                subTokens.append("<unk>")
                break
            }
            subTokens.append(found)
            let advanceBy = found.hasPrefix("##") ? found.count - 2 : found.count
            start = word.index(start, offsetBy: advanceBy)
        }
        return subTokens
    }
}
