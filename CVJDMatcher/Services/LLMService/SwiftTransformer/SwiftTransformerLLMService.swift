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

final class SwiftTransformerLLMService: LLMService {
    fileprivate static let marker = "=== RESPONSE START ==="

    private let modelName: String
    private let bundle: Bundle
    private var tokenizer: Tokenizer!
    private var languageModel: LanguageModel!
    private let generationConfig: GenerationConfig

    var onPartialOuput: ((String) -> Void)?

    init(modelName: String, generationConfig: GenerationConfig, bundle: Bundle = .main) {
        self.modelName = modelName
        self.generationConfig = generationConfig
        self.bundle = bundle
    }

    func loadModel() async throws {
        guard let url = bundle.url(forResource: modelName, withExtension: ".mlmodelc") else {
            throw LLMError.modelNotFound
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        let model = try MLModel(contentsOf: url, configuration: configuration)
        let languageModel = LanguageModel(model: model)
        self.languageModel = languageModel
        guard let tokenizerConfig = try await languageModel.tokenizerConfig else {
            throw LLMError.tokenizerNotFound
        }
        tokenizer = try await AutoTokenizer.from(
            tokenizerConfig: tokenizerConfig,
            tokenizerData: languageModel.tokenizerData
        )
        print("----------------------------------------------------")
        print(" ⚡️ Tokenizer: \(String(describing: tokenizer.self))")
        print("----------------------------------------------------\n\n")
    }

    func generate(prompt: String) async throws -> String {
        guard let languageModel else {
            throw LLMError.modelNotFound
        }
        var config = generationConfig
        config.eosTokenId = tokenizer.eosTokenId
        config.bosTokenId = tokenizer.bosTokenId
        let prompt = prompt + "\n\(SwiftTransformerLLMService.marker)"
        print("----------------------------------------------------")
        print(" ⚡️ Prompt: \(prompt)")
        print("----------------------------------------------------\n\n")
        let result = try await languageModel.generate(
            config: config,
            prompt: prompt,
            callback: { [weak self] explanation in
                guard let self else { return }
                let explanation = explanation.removingPrompt()
                print("----------------------------------------------------")
                print("🦄 Partial explanation: \(explanation)")
                print("----------------------------------------------------\n\n")
                self.onPartialOuput?(explanation)
            }
        )
        return result.removingPrompt()
    }
}

private extension String {
    /// Removes the given `prompt` from the beginning of the string (if exists).
    /// Trims whitespace and newlines after removing.
    func removingPrompt() -> String {
        if let result = components(separatedBy: SwiftTransformerLLMService.marker)
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            return result
        }
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


extension SwiftTransformerLLMService {
    static var llama_2_7b_chat: LLMService {
        SwiftTransformerLLMService(
            modelName: "llama-2-7b-chat",
            generationConfig: GenerationConfig(
                maxNewTokens: 60,
                doSample: true,
                temperature: 0.8,
                topK: 50,
                topP: 0.95
            )
        )
    }

    static var tiny_llama: LLMService {
        SwiftTransformerLLMService(
            modelName: "tiny_llama",
            generationConfig: GenerationConfig(
                maxNewTokens: 120,
                doSample: true,
                temperature: 0.9,
                topK: 40,
                topP: 0.95
            )
        )
    }
}
