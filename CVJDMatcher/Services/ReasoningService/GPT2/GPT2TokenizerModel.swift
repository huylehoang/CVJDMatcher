//
//  GPT2TokenizerModel.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 2/7/25.
//

import Foundation

struct GPT2TokenizerModel: Codable {
    struct BPEModel: Codable {
        let type: String
        let dropout: Double?
        let unk_token: String?
        let continuing_subword_prefix: String
        let end_of_word_suffix: String
        let fuse_unk: Bool
        let byte_fallback: Bool
        let ignore_merges: Bool
        let vocab: [String: Int]
        let merges: [[String]]
    }

    struct SpecialToken: Codable {
        let id: Int
        let content: String
        let single_word: Bool
        let lstrip: Bool
        let rstrip: Bool
        let normalized: Bool
        let special: Bool
    }

    struct ByteLevelComponent: Codable {
        let type: String
        let add_prefix_space: Bool
        let trim_offsets: Bool
        let use_regex: Bool
    }

    struct Truncation: Codable {
        let direction: String
        let max_length: Int
        let strategy: String
        let stride: Int
    }

    struct Padding: Codable {
        struct Strategy: Codable {
            let fixed: Int?

            enum CodingKeys: String, CodingKey {
                case fixed = "Fixed"
            }
        }

        let strategy: Strategy
        let direction: String
        let pad_to_multiple_of: Int?
        let pad_id: Int
        let pad_type_id: Int
        let pad_token: String
    }

    let version: String
    let truncation: Truncation?
    let padding: Padding?
    let added_tokens: [SpecialToken]?
    let normalizer: String?
    let pre_tokenizer: ByteLevelComponent
    let post_processor: ByteLevelComponent
    let decoder: ByteLevelComponent
    let model: BPEModel
}
