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
    private var modelPath: String?

    var onPartialOuput: ((String) -> Void)?

    init(modelName: String, bundle: Bundle = .main) {
        self.modelName = modelName
        self.bundle = bundle
    }

    func loadModel() async throws {
        guard let url = bundle.url(forResource: modelName, withExtension: ".bin") else {
            throw LLMError.modelNotFound
        }
        modelPath = url.path()
    }

    func generate(prompt: String) async throws -> String {
        guard let modelPath else {
            throw LLMError.modelNotFound
        }
        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 512
        options.maxTopk = 40
        options.waitForWeightUploads = true
        options.useSubmodel = false
        options.sequenceBatchSize = 1
        let llmInference = try LlmInference(options: options)
        let stream = llmInference.generateResponseAsync(inputText: prompt)
        print("----------------------------------------------------")
        print(" ⚡️ Prompt: \(prompt)")
        print("----------------------------------------------------\n\n")
        var result = ""
        for try await prediction in stream {
            result += prediction
            print("----------------------------------------------------")
            print("🦄 Prediction: \(result)")
            print("----------------------------------------------------\n\n")
            onPartialOuput?(result.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension MediaPipeLLMService  {
    static var gemma_2b_it_cpu_int8: LLMService {
        MediaPipeLLMService(modelName: "gemma-2b-it-cpu-int8")
    }
}
