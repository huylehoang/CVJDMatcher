//
//  MatchResult.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import Foundation

struct MatchResult: Identifiable {
    let id = UUID()
    let cv: String
    let score: Double
    let explanation: String
    
    var scoreString: String {
        String(format: "%.2f%%", score * 100)
    }
}
