//
//  Chunker.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

protocol Chunker {
    func chunk(text: String) throws -> [Chunk]
}
