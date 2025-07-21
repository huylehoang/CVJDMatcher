//
//  SampleDataView.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 21/7/25.
//

import SwiftUI

struct SampleDataView: View {
    @Environment(\.dismiss) private var dismiss
    private let jd = """
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
    let onApply: (MatchingInputData) -> Void

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("📝 Job Description").font(.headline)) {
                    Text(jd)
                        .font(.system(size: 14))
                }
                Section(header: Text("👤 Candidate CVs").font(.headline)) {
                    ForEach(cvs, id: \.self) { cv in
                        Text(cv)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("Use Sample Data")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(MatchingInputData(jd: jd, cvs: cvs))
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
