//
//  RAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

protocol RAGService {
    func setup() async throws
    func loadData(_ cvs: [String]) throws
    func query(jd: String, onPartial: ((String) -> Void)?) async throws -> String
}

extension RAGService {
    func query(jd: String) async throws -> String {
        try await query(jd: jd, onPartial: nil)
    }
}
