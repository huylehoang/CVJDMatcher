//
//  StsbRobertaLargeEmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 12/7/25.
//

import CoreML

final class StsbRobertaLargeEmbeddingService: EmbeddingService {
    private let modelName: String
    private let vocabName: String
    private let bundle: Bundle
    private let maxLength: Int
    private var model: MLModel?
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
        guard
            let modelUrl = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc"),
            let vocabUrl = Bundle.main.url(forResource: vocabName, withExtension: "json")
        else {
            throw EmbeddingError.modelNotFound
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        model = try MLModel(contentsOf: modelUrl, configuration: configuration)
        let data = try Data(contentsOf: vocabUrl)
        vocab = try JSONDecoder().decode([String:Int].self, from: data)
    }

    func embed(_ text: String) throws -> [Float] {
        guard let model else {
            throw EmbeddingError.modelNotFound
        }
        let (inputIDs, attentionMask) = tokenize(text)
        let idsArr = MLMultiArray.from(inputIDs, dims: 2)
        let maskArr = MLMultiArray.from(attentionMask, dims: 2)
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": idsArr,
            "attention_mask": maskArr
        ])
        let output = try model.prediction(from: provider)
        guard
            let name = output.featureNames.first,
            let embeddings = output.featureValue(for: name)?.multiArrayValue
        else {
            throw EmbeddingError.modelNotFound
        }
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
