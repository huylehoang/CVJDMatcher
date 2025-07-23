//
//  PromptServiceProvider.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 23/7/25.
//

protocol PromptServiceProvider {
    var promptService: PromptService { get }
}

struct StandardPromptServiceProvider: PromptServiceProvider {
    var promptService: PromptService {
        switch appEnvironment.promptServiceType {
        case .v1:
            PromptServiceV1()
        case .v2:
            PromptServiceV2()
        }
    }

    private let appEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment = StandardAppEnvironment.shared) {
        self.appEnvironment = appEnvironment
    }
}
