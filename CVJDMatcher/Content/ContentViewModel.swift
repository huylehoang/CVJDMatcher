//
//  ContentViewModel.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    private let ragServiceProvider: RAGServiceProvider
    private let appLogger: AppLogger
    private var currentTask: Task<Void, Never>? // track running task
    @Published var result: String?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    private(set) var jd = ""
    private var cvs = [String]()

    init(
        ragServiceProvider: RAGServiceProvider = StandardRAGServiceProvider(),
        appLogger: AppLogger = ConsoleAppLogger()
    ) {
        self.ragServiceProvider = ragServiceProvider
        self.appLogger = appLogger
    }

    func runMatchingFlow() {
        result = nil
        errorMessage = nil
        isLoading = true
        // Cancel previous task if running
        currentTask?.cancel()
        let ragService = ragServiceProvider.ragService
        // Use Task.detached to run CPU-heavy work off the main thread

        // What is Task.detached?
        // A way to run work **outside of the current actor**, usually off the main thread.
        // It's useful for **heavy computation** that shouldn't block the UI.

        // Why we use Task.detached here?
        // - Embedding + reasoning with Core ML is CPU-intensive
        // - We want to keep the UI responsive
        // - Detached task runs in background without violating MainActor rules
        currentTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard !Task.isCancelled, let self else { return }
            do {
                await appLogger.logRunMatchingFlow()
                try await ragService.setup()
                try Task.checkCancellation()
                try await ragService.indexData(self.cvs)
                try Task.checkCancellation()
                let result = try await ragService.generateReponse(for: self.jd) { result in
                    if !Task.isCancelled {
                        DispatchQueue.main.async {
                            self.result = result
                        }
                    }
                }
                try Task.checkCancellation()
                await appLogger.logResult(result)
                await MainActor.run {
                    self.isLoading = false
                    self.result = result
                }
            } catch is CancellationError {
                await appLogger.logCancelled()
            } catch AppError.inferenceTimedOut {
                await appLogger.logInferenceTimeout()
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await appLogger.logError(error)
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func setup(jd: String, cvs: [String]) {
        self.jd = jd
        self.cvs = cvs
        isLoading = false
        result = nil
        errorMessage = nil
    }
}
