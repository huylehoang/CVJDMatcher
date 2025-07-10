//
//  RAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 9/7/25.
//

protocol RAGService {
    func loadModels() async throws
    func loadData(_ cvs: [String]) throws
    func query(jd: String, onPartial: (([MatchResult]) -> Void)?) throws -> [MatchResult]
}

extension RAGService {
    func query(jd: String) throws -> [MatchResult] {
        try query(jd: jd, onPartial: nil)
    }
}
