//
//  LLMServiceProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 23/7/25.
//

protocol LLMServiceProvider {
    var llmService: LLMService { get }
}

struct StandardLLMServiceProvider: LLMServiceProvider {
    var llmService: LLMService {
        switch appEnvironment.llmServiceType {
        case .media_pipe_gemma_2b_it_cpu_int8:
            MediaPipeLLMService.gemma_2b_it_cpu_int8
        case .firebase_gemini_1_5_flash:
            FirebaseLLMService.gemini_1_5_flash
        case .token_based_llama_2_7b_chat:
            TokenBasedLLMService.llama_2_7b_chat
        case .token_based_tiny_llama:
            TokenBasedLLMService.tiny_llama
        case .swift_transformer_llama_2_7b_chat:
            SwiftTransformerLLMService.llama_2_7b_chat
        case .swift_transformer_tiny_llama:
            SwiftTransformerLLMService.tiny_llama
        }
    }

    private let appEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment = StandardAppEnvironment.shared) {
        self.appEnvironment = appEnvironment
    }
}
