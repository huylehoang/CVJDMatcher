//
//  PromptProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 13/7/25.
//

enum PromptProvider {
    static func multiCandidatePrompt(jd: String, results: [MatchResult], topK: Int) -> String {
        """
        You are an expert technical recruiter. Here's a job description and \(topK) candidates. \
        Who is the best fit? Why?
        
        Job Description:
        \(jd)
        
        \(results.candidateBlocks)
        
        Please summarize strengths and weaknesses of each, and name the best candidate.
        """
    }
}

private extension [MatchResult] {
    var candidateBlocks: String {
        enumerated()
            .map { "Candidate \($0 + 1): \($1.cleanedCV)" }
            .joined(separator: "\n\n")
    }
}

private extension MatchResult {
    var cleanedCV: String {
        cv.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
