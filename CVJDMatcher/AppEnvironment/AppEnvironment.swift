//
//  AppEnvironment.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 14/7/25.
//

final class AppEnvironment {
    static let shared = AppEnvironment()

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
