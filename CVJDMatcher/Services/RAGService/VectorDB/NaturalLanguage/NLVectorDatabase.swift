//
//  NLVectorDatabase.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

import ObjectBox

final class NLVectorDatabase: VectorDatabase {
    private let objectBoxDatabase: ObjectBoxDatabase
    private var box: Box<NLVector>?

    init(objectBoxDatabase: ObjectBoxDatabase = StandardObjectBoxDatabase.shared) {
        self.objectBoxDatabase = objectBoxDatabase
    }

    func setup() throws {
        let store = try objectBoxDatabase.getStore()
        box = store.box(for: NLVector.self)
    }

    /// Clear all indexed candidates
    func clear() throws {
        guard let box else {
            throw AppError.boxNotFound
        }
        try box.removeAll()
    }

    /// Index a list of texts with their embeddings
    func index(vectors: [(text: String, embedding: [Float])]) throws {
        guard let box else {
            throw AppError.boxNotFound
        }
        let objs = vectors.map { NLVector(text: $0.text, embedding: $0.embedding) }
        try box.put(objs)
    }

    /// Query top-K candidates given a vector
    func search(queryVector: [Float], topK: Int) throws -> [Vector] {
        guard let box else {
            throw AppError.boxNotFound
        }
        return try box
            .query {
                NLVector.embedding.nearestNeighbors(queryVector: queryVector, maxCount: topK)
            }
            .build()
            .find()
    }
}
