//
//  VectorDatabase.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

import Foundation

protocol VectorDatabase {
    func setup() throws
    func clear() throws
    func index(vectors: [(text: String, embedding: [Float])]) throws
    func search(queryVector: [Float], topK: Int) throws -> [Vector]
}

enum VectorDatabaseError: Error, LocalizedError {
    case setupFailed
    case clearFailed
    case indexFailed
    case searchFailed

    var errorDescription: String? {
        switch self {
        case .setupFailed:
            "Setup Vector Database failed"
        case .clearFailed:
            "Clear Vector Database failed"
        case .indexFailed:
            "Index Vector Database failed"
        case .searchFailed:
            "Search Vector Database failed"
        }
    }
}
