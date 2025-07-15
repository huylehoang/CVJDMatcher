//
//  PromptServiceV1.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

struct PromptServiceV1: PromptService {
    func prompt(jd: String, cvs: String, topK: Int) -> String {
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
