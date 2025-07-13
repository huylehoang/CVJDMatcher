//
//  RAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

protocol RAGService {
    /// Prepare model or resources before usage.
    func setup() async throws
    /// Load documents/text chunks into the vector store.
    func indexData(_ data: [String]) throws
    /// Process query text and return generated response.
    /// - Parameters:
    ///   - query: input text for retrieval
    ///   - onPartial: optional callback for streaming partial outputs
    func generateReponse(for query: String, onPartial: ((String) -> Void)?) async throws -> String
}

extension RAGService {
    func generateReponse(for query: String) async throws -> String {
        try await generateReponse(for: query, onPartial: nil)
    }
}
