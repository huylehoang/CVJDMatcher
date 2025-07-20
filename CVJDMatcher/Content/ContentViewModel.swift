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
        """,
        """
        Tran X is a Senior iOS Developer with 6 years experience building finance and e‑commerce \
        apps using Swift, MVVM, Combine, and UIKit. Designed modular app architectures with Swift \
        Package Manager and integrated Core ML.
        """,
        """
        Vu Y is a Mid‑Level iOS Engineer with 4 years in SwiftUI, MVVM, and Combine. Delivered \
        healthcare and fintech applications, optimized performance and implemented XCTest for \
        robust testing.
        """,
        """
        Nguyen K is an Android Developer with 5 years of experience using Kotlin, Jetpack Compose, \
        and MVVM. Led Java‑to‑Kotlin migrations, but has no professional iOS background.
        """,
        """
        Tran D is a Frontend Engineer specializing in React, Next.js, and TypeScript with 5 years \
        experience building dashboards and responsive design systems. No mobile development \
        experience.
        """,
        """
        Mai E is a Full‑Stack Engineer skilled in Node.js, React, and AWS. Built microservices for \
        e‑commerce and implemented CI/CD pipelines over 5 years.
        """,
        """
        Huy F is a QA Automation Engineer specializing in Selenium, Cypress, and Java, with 5 \
        years in Agile teams. Automated regression testing and integrated CI workflows.
        """,
        """
        Khanh G is a DevOps Engineer with 7 years experience in Kubernetes, Terraform, and \
        Jenkins. Managed Docker/K8s clusters and improved deployment pipelines reliability.
        """
    ]

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
                try ragService.indexData(self.cvs)
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
}
