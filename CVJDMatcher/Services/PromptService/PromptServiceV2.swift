//
//  PromptServiceV2.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

struct PromptServiceV2: PromptService {
    func prompt(jd: String, cvs: String, topK: Int) -> String {
        """
        You are an expert technical recruiter. Evaluate the following \(topK) candidates solely \
        based on their CV content in relation to the job description.
        
        Job Description:
        \(jd)
        
        Candidate Profiles:
        \(cvs)
        
        Instructions:
        1. For each candidate, provide a 1–2 sentence summary highlighting their technical \
        background, years of experience, and notable technologies.
        2. Think step-by-step to determine if the candidate fits the job description: compare \
        required skills, years of experience, tools used, and relevant projects.
        3. Mention strengths and weaknesses for each candidate.
        4. Conclude with a comparative analysis summarizing which candidates are strong, \
        moderate, or poor fits.
        
        Output Format:
        Candidate X:
        - Summary: ...
        - Strengths: ...
        - Weaknesses: ...
        
        Final Comparison Summary:
        ...
        
        Begin your reasoning now.
        """
    }
}
