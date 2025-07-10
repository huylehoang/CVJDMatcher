//
//  SlidingWindowChunker.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

import Foundation

/// SlidingWindowChunker splits long text into overlapping chunks of words.
/// - windowSize: number of words per chunk
/// - stride: how many words to move the window each step (allows overlap)
///
/// Example with text: "Nguyen A: Senior iOS Developer with Swift and MVVM"
/// Words = ["Nguyen","A:","Senior","iOS","Developer","with","Swift","and","MVVM"]
/// With windowSize = 5, stride = 3:
///   Chunk 1: words[0..<5] = "Nguyen A: Senior iOS Developer"
///   Chunk 2: words[3..<8] = "iOS Developer with Swift and"
///   Chunk 3: words[6..<9] = "Swift and MVVM"
///
/// Benefits:
/// - Maintains context across chunk boundaries via overlap
/// - Enables per-chunk embedding/retrieval in RAG
/// - Metadata allows tracing back to original position
final class SlidingWindowChunker: Chunker {
    private let windowSize: Int
    private let stride: Int

    init(windowSize: Int = 5, stride: Int = 3) {
        precondition(stride <= windowSize, "Stride must be ≤ windowSize")
        self.windowSize = windowSize
        self.stride = stride
    }

    func chunk(text: String) throws -> [Chunk] {
        // 1️⃣ Split the text into words by whitespace
        let tokens = text.split(separator: " ")
        let words = tokens.map(String.init)
        var chunks = [Chunk]()
        var start = 0
        // 2️⃣ Slide window across words
        while start < words.count {
            let end = min(start + windowSize, words.count)
            let chunkWords = Array(words[start..<end])
            let chunkText = chunkWords.joined(separator: " ")
            // 3️⃣ Metadata for potential downstream use (e.g., trace to original CV)
            let metadata: [String: Any] = [
                "word_range": [start, end],
                "text_length": chunkWords.count
            ]
            // 4️⃣ Create and store the chunk
            chunks.append(Chunk(text: chunkText, metadata: metadata))
            // 5️⃣ Advance the window by stride to allow overlap
            start += stride
        }
        return chunks
    }
}
