//
//  CoreMLIO.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 20/7/25.
//

import CoreML

protocol CoreMLInputConvertible {
    func toMLFeatureProvider() throws -> MLFeatureProvider
}

protocol CoreMLOutputDecodable {
    init(from featureProvider: MLFeatureProvider) throws
}

struct CoreMLTokenInput: CoreMLInputConvertible {
    let inputIDs: MLMultiArray
    let attentionMask: MLMultiArray

    func toMLFeatureProvider() throws -> MLFeatureProvider {
        try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": inputIDs,
            "attention_mask": attentionMask
        ])
    }
}

struct CoreMLTokenOutput: CoreMLOutputDecodable {
    let logits: MLMultiArray

    init(from featureProvider: MLFeatureProvider) throws {
        guard
            let name = featureProvider.featureNames.first,
            let logits = featureProvider.featureValue(for: name)?.multiArrayValue
        else {
            throw AppError.invalidOutput
        }
        self.logits = logits
    }
}
