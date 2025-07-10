//
//  SwiftTransformerReasoningService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 10/7/25.
//

import Foundation
import Models
import Tokenizers
import Generation
import CoreML

final class SwiftTransformerReasoningService: ReasoningService {
    fileprivate static let marker = "=== RESPONSE START ==="

    private var tokenizer: Tokenizer!
    private var model: LanguageModel!
    private let topK = 50
    private let maxNewTokens = 60

    var onPartialExplanation: ((String) -> Void)?

    var constructPrompt: ConstructPrompt = { jd, cv in
        """
        You are an AI model helping match Job Descriptions (JD) with Candidate CVs.
        
        Respond in **exactly this format** and focus **only on the technical match**:
        Job: <copied JD>
        CV: <copied CV>
        Match: Yes | No
        Reason: <1-2 short technical reasons why they match or not>
        
        Do not write anything outside of this format. No summaries, no greetings.
        
        === Format Example ===
        Job: Looking for iOS Developer with Swift, Combine
        CV: Nguyen A: Senior iOS Developer with Swift and MVVM
        Match: Yes
        Reason: Strong iOS and Swift experience; MVVM shows architecture knowledge; \
        Combine is learnable.
        
        === Another Example ===
        Job: Backend Developer with Node.js, MongoDB
        CV: Jenny B: Frontend Developer with React, TailwindCSS
        Match: No
        Reason: Candidate lacks backend or Node.js experience.
        
        === Now Evaluate ===
        Job: \(jd)
        CV: \(cv)
        \(SwiftTransformerReasoningService.marker)
        """
    }

    func loadModel() async throws {
        let loadedModel = try await llama_2_7b_chat.load()
        model = LanguageModel(model: loadedModel.model)
        tokenizer = try await AutoTokenizer.from(
            tokenizerConfig: model.tokenizerConfig!,
            tokenizerData: model.tokenizerData
        )
        model.model.configuration.computeUnits = .all
        print("----------------------------------------------------")
        print(" ⚡️ Tokenizer: \(String(describing: tokenizer.self))")
        print("----------------------------------------------------\n\n")
    }

    func explain(jd: String, cv: String) async throws -> String {
        var config = GenerationConfig(maxNewTokens: 60, topK: 50)
        config.eosTokenId = tokenizer.eosTokenId
        config.bosTokenId = tokenizer.bosTokenId
        let prompt = constructPrompt(jd, cv)
        print("----------------------------------------------------")
        print(" ⚡️ Prompt: \(prompt)")
        print("----------------------------------------------------\n\n")
        let result = try await model.generate(
            config: config,
            prompt: prompt,
            callback: { [weak self] explanation in
                guard let self else { return }
                let explanation = explanation.removingPrompt()
                print("----------------------------------------------------")
                print("🦄 Partial explanation: \(explanation)")
                print("----------------------------------------------------\n\n")
                self.onPartialExplanation?(explanation)
            }
        )
        return result.removingPrompt()
    }
}

private extension String {
    /// Removes the given `prompt` from the beginning of the string (if exists).
    /// Trims whitespace and newlines after removing.
    func removingPrompt() -> String {
        if let result = components(separatedBy: SwiftTransformerReasoningService.marker)
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            return result
        }
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
