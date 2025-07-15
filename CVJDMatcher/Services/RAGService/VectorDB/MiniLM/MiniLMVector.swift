//
//  MiniLMVector.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

import ObjectBox

// objectbox: entity
class MiniLMVector: Vector {
    // objectbox: id
    var id: Id = 0
    var text: String
    // objectbox:hnswIndex: dimensions=384
    var embedding: [Float]

    init(text: String, embedding: [Float]) {
        self.text = text
        self.embedding = embedding
    }

    required init() {
        self.text = ""
        self.embedding = []
    }
}
