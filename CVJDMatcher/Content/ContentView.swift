//
//  ContentView.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    // JD section
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Job Description")
                                .font(.headline)
                            Text(viewModel.jd)
                                .font(.body)
                        }
                        .padding(.vertical, 8)
                    }
                    // Error section
                    if let error = viewModel.errorMessage {
                        Section {
                            Text("⚠️ \(error)")
                                .foregroundColor(.red)
                        }
                    }
                    // Match results
                    ForEach(viewModel.matchResults) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(result.cv)
                                .font(.headline)
                            Text("Score: \(result.scoreString)")
                                .font(.subheadline)
                            Text(result.explanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
                // Centered loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView("Analyzing CVs...")
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .navigationTitle("CV Match Results")
            .onAppear {
                viewModel.runMatchingFlow()
            }
        }
    }
}

#Preview {
    ContentView()
}
