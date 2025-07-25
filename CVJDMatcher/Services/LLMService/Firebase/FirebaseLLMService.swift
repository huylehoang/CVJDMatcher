//
//  FirebaseLLMService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 13/7/25.
//

import FirebaseAI

final class FirebaseLLMService: LLMService {
    private let modelName: String
    private let appLogger: AppLogger
    private var model: GenerativeModel?

    var onPartialOuput: ((String) -> Void)?

    init(modelName: String, appLogger: AppLogger = ConsoleAppLogger()) {
        self.modelName = modelName
        self.appLogger = appLogger
    }

    func loadModel() async throws {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        model = ai.generativeModel(modelName: modelName)
    }

    func generateResponse(for prompt: String) async throws -> String {
        guard let model else {
            throw AppError.modelNotFound
        }
        appLogger.logPrompt(prompt)
        return try await withTimeout { [weak self] in
            var result = ""
            let stream = try model.generateContentStream(prompt)
            for try await chunk in stream {
                try Task.checkCancellation()
                if let part = chunk.text {
                    result += part
                    self?.appLogger.logPrediction(result)
                    self?.onPartialOuput?(result)
                }
            }
            return result
        }
    }
}

extension FirebaseLLMService {
    static var gemini_1_5_flash: LLMService {
        FirebaseLLMService(modelName: "gemini-1.5-flash")
    }
}
