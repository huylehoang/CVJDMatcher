//
//  PromptService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

protocol PromptService {
    func prompt(jd: String, cvs: String, topK: Int) -> String
}
