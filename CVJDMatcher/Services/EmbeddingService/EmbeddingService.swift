//
//  EmbeddingService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import Foundation

protocol EmbeddingService {
    func loadModel() async throws
    func embed(_ text: String) throws -> [Float]
}
