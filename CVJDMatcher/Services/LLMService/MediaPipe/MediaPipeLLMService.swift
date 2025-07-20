//
//  MediaPipeLLMService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 11/7/25.
//

import MediaPipeTasksGenAI
import Foundation

final class MediaPipeLLMService: LLMService {
    private let modelName: String
    private let bundle: Bundle
    private let maxTokens: Int
    private let temperature: Float
    private let topK: Int
    private let topP: Float
    private let appLogger: AppLogger
    private var session: LlmInference.Session?

    var onPartialOuput: ((String) -> Void)?

    init(
        modelName: String,
        bundle: Bundle = .main,
        maxTokens: Int = 1024,
        temparature: Float = 0.6,
        topK: Int = 50,
        topP: Float = 0.9,
        appLogger: AppLogger = ConsoleAppLogger()
    ) {
        self.modelName = modelName
        self.bundle = bundle
        self.maxTokens = maxTokens
        self.temperature = temparature
        self.topK = topK
        self.topP = topP
        self.appLogger = appLogger
    }

    func loadModel() async throws {
        guard let url = bundle.url(forResource: modelName, withExtension: ".bin") else {
            throw AppError.modelNotFound
        }
        let options = LlmInference.Options(modelPath: url.path())
        options.maxTokens = maxTokens
        let llmInference = try LlmInference(options: options)
        let sessionOptions = LlmInference.Session.Options()
        sessionOptions.temperature = temperature
        sessionOptions.topk = topK
        sessionOptions.topp = topP
        session = try LlmInference.Session(llmInference: llmInference, options: sessionOptions)
    }

    func generateResponse(for prompt: String) async throws -> String {
        guard let session else {
            throw AppError.modelNotFound
        }
        try session.addQueryChunk(inputText: prompt)
        let stream = session.generateResponseAsync()
        appLogger.logPrompt(prompt)
        return try await withTimeout { [weak self] in
            var result = ""
            for try await prediction in stream {
                try Task.checkCancellation()
                result += prediction
                self?.appLogger.logPrediction(result)
                self?.onPartialOuput?(result)
            }
            return result
        }
    }
}

extension MediaPipeLLMService  {
    static var gemma_2b_it_cpu_int8: LLMService {
        MediaPipeLLMService(
            modelName: "gemma_2b_it_cpu_int8",
            maxTokens: 1024,
            temparature: 0.6,
            topK: 50,
            topP: 0.9
        )
    }
}
