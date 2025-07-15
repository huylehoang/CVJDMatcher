//
//  PromptProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 13/7/25.
//

enum PromptProvider {
    static func multiCandidatePrompt(jd: String, cvs: String, topK: Int) -> String {
        """
        You are an expert technical recruiter. Here's a job description and \(topK) candidates. \
        Who is the best fit? Why?
        
        Job Description:
        \(jd)
        
        \(cvs)
        
        Please summarize strengths and weaknesses of each, and name the best candidate.
        """
    }
}
