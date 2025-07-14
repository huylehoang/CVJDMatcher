//
//  FirebaseLLMService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 13/7/25.
//

import FirebaseAI

final class FirebaseLLMService: LLMService {
    private let modelName: String
    private var model: GenerativeModel?

    var onPartialOuput: ((String) -> Void)?

    init(modelName: String) {
        self.modelName = modelName
    }

    func loadModel() async throws {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        model = ai.generativeModel(modelName: modelName)
    }

    func generateResponse(for prompt: String) async throws -> String {
        guard let model else {
            throw LLMError.modelNotFound
        }
        var result = ""
        let stream = try model.generateContentStream(prompt)
        for try await chunk in stream {
            if let part = chunk.text {
                result += part
                print("----------------------------------------------------")
                print("🦄 Prediction: \(result)")
                print("----------------------------------------------------\n\n")
                onPartialOuput?(result)
            }
        }
        return result
    }
}

extension FirebaseLLMService {
    static var gemini_1_5_flash: LLMService {
        FirebaseLLMService(modelName: "gemini-1.5-flash")
    }
}
