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
    private let ragService: RAGService
    @Published var matchResults = [MatchResult]()
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
        """
    ]

    init(ragService: RAGService = LocalRAGService()) {
        self.ragService = ragService
    }

    func runMatchingFlow() {
        isLoading = true
        // Use Task.detached to run CPU-heavy work off the main thread

        // What is Task.detached?
        // A way to run work **outside of the current actor**, usually off the main thread.
        // It's useful for **heavy computation** that shouldn't block the UI.

        // Why we use Task.detached here?
        // - Embedding + reasoning with Core ML is CPU-intensive
        // - We want to keep the UI responsive
        // - Detached task runs in background without violating MainActor rules
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                try await self.ragService.setup()
                try await self.ragService.loadData(self.cvs)
                let matchResults = try await self.ragService.query(jd: self.jd) { matchResuls in
                    DispatchQueue.main.async {
                        self.matchResults = matchResuls
                    }
                }
                await MainActor.run {
                    self.matchResults = matchResults
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
