//
//  AppEnvironment.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 14/7/25.
//

enum RAGServiceType: String, CaseIterable {
    case inMemory
    case vectorDB
}

enum EmbeddingServiceType: String, CaseIterable {
    case mini_lm
    case natural_language_for_english
    case stsb_roberta_large
}

enum LLMServiceType: String, CaseIterable {
    case media_pipe_gemma_2b_it_cpu_int8
    case firebase_gemini_1_5_flash
    case token_based_llama_2_7b_chat
    case token_based_tiny_llama
    case swift_transformer_llama_2_7b_chat
    case swift_transformer_tiny_llama
}

enum PromptServiceType: String, CaseIterable {
    case v1
    case v2
}

protocol AppEnvironment {
    var ragServiceType: RAGServiceType { get }
    var llmServiceType: LLMServiceType { get }
    var embeddingServiceType: EmbeddingServiceType { get }
    var promptServiceType: PromptServiceType { get }
}

final class StandardAppEnvironment: AppEnvironment {
    static let shared = StandardAppEnvironment()

    private(set) var ragServiceType: RAGServiceType = .vectorDB
    private(set) var llmServiceType: LLMServiceType = .media_pipe_gemma_2b_it_cpu_int8
    private(set) var embeddingServiceType: EmbeddingServiceType = .mini_lm
    private(set) var promptServiceType: PromptServiceType = .v1

    private init() {}

    func set(ragServiceType: RAGServiceType) {
        self.ragServiceType = ragServiceType
    }

    func set(embeddingServiceType: EmbeddingServiceType) {
        self.embeddingServiceType = embeddingServiceType
    }

    func set(llmServiceType: LLMServiceType) {
        self.llmServiceType = llmServiceType
    }

    func set(promptServiceType: PromptServiceType) {
        self.promptServiceType = promptServiceType
    }
}
