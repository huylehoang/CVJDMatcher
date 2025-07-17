//
//  RAGServiceProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 14/7/25.
//

protocol RAGServiceProvider {
    var ragService: RAGService { get }
}

final class StandardRAGServiceProvider: RAGServiceProvider {
    private let appEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment = StandardAppEnvironment.shared) {
        self.appEnvironment = appEnvironment
    }

    private var embeddingService: EmbeddingService {
        switch appEnvironment.embeddingServiceType {
        case .mini_lm:
            MiniLMEmbeddingService()
        case .natural_language_for_english:
            NLEmbeddingService.forEnglish
        case .stsb_roberta_large:
            StsbRobertaLargeEmbeddingService()
        }
    }

    private var llmService: LLMService {
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

    private var promptService: PromptService {
        switch appEnvironment.promptServiceType {
        case .v1:
            PromptServiceV1()
        case .v2:
            PromptServiceV2()
        }
    }

    private var vectorDB: VectorDatabase {
        switch appEnvironment.embeddingServiceType {
        case .mini_lm:
            MiniLMVectorDatabase()
        case .natural_language_for_english:
            NLVectorDatabase()
        case .stsb_roberta_large:
            StsbVectorDatabase()
        }
    }

    var ragService: RAGService {
        switch appEnvironment.ragServiceType {
        case .inMemory:
            InMemoryRAGService(
                embeddingService: embeddingService,
                llmService: llmService,
                promptService: promptService
            )
        case .vectorDB:
            VectorDBRAGService(
                embeddingService: embeddingService,
                llmService: llmService,
                promptService: promptService,
                vectorDB: vectorDB
            )
        }
    }
}
