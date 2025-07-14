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
    private let generateTimeout: TimeInterval
    private var modelPath: String?

    var onPartialOuput: ((String) -> Void)?

    init(modelName: String, bundle: Bundle = .main, generateTimeout: TimeInterval = 60) {
        self.modelName = modelName
        self.bundle = bundle
        self.generateTimeout = generateTimeout
    }

    func loadModel() async throws {
        guard let url = bundle.url(forResource: modelName, withExtension: ".bin") else {
            throw LLMError.modelNotFound
        }
        modelPath = url.path()
    }

    func generateResponse(for prompt: String) async throws -> String {
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
        // Race between stream processing and timeout
        return try await withThrowingTaskGroup(of: String.self) { [weak self] group in
            group.addTask {
                // Task to read stream
                for try await prediction in stream {
                    result += prediction
                    try Task.checkCancellation()
                    print("----------------------------------------------------")
                    print("🦄 Prediction: \(result)")
                    print("----------------------------------------------------\n\n")
                    self?.onPartialOuput?(result)
                }
                return result
            }
            group.addTask {
                guard let self else {
                    throw TimeoutError()
                }
                try await Task.sleep(nanoseconds: UInt64(self.generateTimeout * 1_000_000_000))
                throw TimeoutError()
            }
            defer {
                group.cancelAll()
            }
            do {
                let output = try await group.next()!
                return output
            } catch is TimeoutError {
                return result
            }
        }
    }

    private struct TimeoutError: Error {}
}

extension MediaPipeLLMService  {
    static var gemma_2b_it_cpu_int8: LLMService {
        MediaPipeLLMService(modelName: "gemma-2b-it-cpu-int8")
    }
}
