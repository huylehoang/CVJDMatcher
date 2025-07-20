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
