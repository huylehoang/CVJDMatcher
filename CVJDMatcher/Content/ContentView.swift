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
                // Match result
                if let matchResult = viewModel.matchResult {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(matchResult.cv)
                                .font(.headline)
                            Text("Score: \(matchResult.scoreString)")
                                .font(.subheadline)
                            Text(matchResult.explanation)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                // Loading indicator shown at bottom of list
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Analyzing next...")
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.plain)
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
