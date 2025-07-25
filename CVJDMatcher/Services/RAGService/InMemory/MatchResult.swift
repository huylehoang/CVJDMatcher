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
    let score: Float
}
