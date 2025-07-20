//
//  CoreMLPipeline.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 20/7/25.
//

import CoreML

final class CoreMLPipeline<Input: CoreMLInputConvertible, Output: CoreMLOutputDecodable> {
    let model: MLModel

    init(modelName: String, bundle: Bundle = .main) throws {
        model = try ModelLoader.loadMLModel(modelName: modelName, bundle: bundle)
    }

    func predict(input: Input) throws -> Output {
        let provider = try input.toMLFeatureProvider()
        let prediction = try model.prediction(from: provider)
        return try Output(from: prediction)
    }
}
