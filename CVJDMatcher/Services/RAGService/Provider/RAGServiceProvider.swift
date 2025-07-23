//
//  RAGServiceProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 14/7/25.
//

protocol RAGServiceProvider {
    var ragService: RAGService { get }
}

struct StandardRAGServiceProvider: RAGServiceProvider {
    var ragService: RAGService {
        switch appEnvironment.ragServiceType {
        case .inMemory:
            InMemoryRAGService(
                embeddingService: embeddingServiceProvider.embeddingService,
                llmService: llmServiceProvider.llmService,
                promptService: promptServiceProvider.promptService
            )
        case .vectorDB:
            VectorDBRAGService(
                embeddingService: embeddingServiceProvider.embeddingService,
                llmService: llmServiceProvider.llmService,
                promptService: promptServiceProvider.promptService,
                vectorDB: vectorDBProvider.vectorDB
            )
        }
    }

    private let embeddingServiceProvider: EmbeddingServiceProvider
    private let llmServiceProvider: LLMServiceProvider
    private let promptServiceProvider: PromptServiceProvider
    private let vectorDBProvider: VectorDatabaseProvider
    private let appEnvironment: AppEnvironment

    init(
        appEnvironment: AppEnvironment = StandardAppEnvironment.shared,
        embeddingServiceProvider: EmbeddingServiceProvider = StandardEmbeddingServiceProvider(),
        llmServiceProvider: LLMServiceProvider = StandardLLMServiceProvider(),
        promptServiceProvider: PromptServiceProvider = StandardPromptServiceProvider(),
        vectorDBProvider: VectorDatabaseProvider = StandardVectoirDatabaseProvider()
    ) {
        self.appEnvironment = appEnvironment
        self.embeddingServiceProvider = embeddingServiceProvider
        self.llmServiceProvider = llmServiceProvider
        self.promptServiceProvider = promptServiceProvider
        self.vectorDBProvider = vectorDBProvider
    }
}
