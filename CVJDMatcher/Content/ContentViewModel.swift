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
    @Published var result: String?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    private var currentTask: Task<Void, Never>? // track running task
    let jd = """
    We are hiring a passionate iOS Developer to join our mobile team. \
    The ideal candidate should have:
    - 3+ years of experience building native iOS applications
    - Proficiency in Swift and Combine
    - Experience with MVVM architecture
    - Familiarity with performance optimization and memory management
    - Bonus: experience with SwiftUI, modular architecture, or Core ML
    """
    private let cvs = [
        """
        Nguyen A is a Senior iOS Engineer with over 5 years of experience developing apps \
        for finance and e-commerce. Skilled in Swift, MVVM, Combine, and UIKit. Recently worked \
        on a modular iOS architecture project using Swift Package Manager. Experienced with \
        CoreData, REST APIs, and performance tuning.
        """,
        """
        Tran B is a Frontend Engineer specializing in web development using React, Next.js, \
        and TypeScript. Familiar with design systems and responsive UI. No mobile development \
        experience. Mainly worked on dashboard systems and internal tools for a logistics company.
        """,
        """
        Le C is an Android Developer with strong knowledge in Kotlin, Jetpack Compose, \
        and MVVM. Has worked on ride-hailing and fintech apps. Led the Android migration from \
        Java to Kotlin. No professional iOS experience, but has contributed to Flutter-based \
        side projects.
        """
    ]

    init(ragServiceProvider: RAGServiceProvider = DefaultRAGServiceProvider()) {
        self.ragServiceProvider = ragServiceProvider
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
                try await ragService.setup()
                try Task.checkCancellation()
                try ragService.indexData(self.cvs)
                try Task.checkCancellation()
                let result = try await ragService.generateReponse(for: self.jd) { result in
                    DispatchQueue.main.async {
                        self.result = result
                    }
                }
                try Task.checkCancellation()
                print("----------------------------------------------------")
                print("🦄 Result: \(result)")
                print("----------------------------------------------------\n\n")
                await MainActor.run {
                    self.result = result
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
