//
//  RAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

protocol RAGService {
    func loadModels() async throws
    func loadData(_ cvs: [String]) throws
    func query(jd: String, onPartial: (([MatchResult]) -> Void)?) async throws -> [MatchResult]
}

extension RAGService {
    func query(jd: String) async throws -> [MatchResult] {
        try await query(jd: jd, onPartial: nil)
    }
}
