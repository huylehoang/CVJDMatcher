//
//  ModelLoader.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 20/7/25.
//

import CoreML

enum ModelLoader {
    static func loadMLModel(modelName: String, bundle: Bundle = .main) throws -> MLModel {
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw AppError.modelNotFound
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        let model = try MLModel(contentsOf: url, configuration: configuration)
        return model
    }
}
