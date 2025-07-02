//
//  GPT2ReasoningTokenizer.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 2/7/25.
//

import Foundation
import CoreML

protocol ReasoningTokenizer {
    func encode(_ text: String, maxLength: Int) throws -> MLMultiArray
    func decode(from logits: MLMultiArray) throws -> String
}
