//
//  VectorDatabaseProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 23/7/25.
//

protocol VectorDatabaseProvider {
    var vectorDB: VectorDatabase { get }
}

struct StandardVectoirDatabaseProvider: VectorDatabaseProvider {
    var vectorDB: VectorDatabase {
        switch appEnvironment.embeddingServiceType {
        case .mini_lm:
            MiniLMVectorDatabase()
        case .natural_language_for_english:
            NLVectorDatabase()
        case .stsb_roberta_large:
            StsbVectorDatabase()
        }
    }

    private let appEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment = StandardAppEnvironment.shared) {
        self.appEnvironment = appEnvironment
    }
}
