//
//  EmbeddingServiceProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 23/7/25.
//

protocol EmbeddingServiceProvider {
    var embeddingService: EmbeddingService { get }
}

struct StandardEmbeddingServiceProvider: EmbeddingServiceProvider {
    var embeddingService: EmbeddingService {
        switch appEnvironment.embeddingServiceType {
        case .mini_lm:
            MiniLMEmbeddingService()
        case .natural_language_for_english:
            NLEmbeddingService.forEnglish
        case .stsb_roberta_large:
            StsbRobertaLargeEmbeddingService()
        }
    }

    private let appEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment = StandardAppEnvironment.shared) {
        self.appEnvironment = appEnvironment
    }
}
