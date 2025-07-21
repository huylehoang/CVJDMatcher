//
//  ContentView.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import SwiftUI

enum DataSourceOption: String, CaseIterable, Identifiable {
    case sampleData = "Try with Sample Data"
    case uploadFiles = "Upload Files"

    var id: String {
        rawValue
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showSettings = false
    @State private var showSourceDialog = false
    @State private var selectedSource: DataSourceOption?
    private let analyzingText = " ● Analyzing..."

    var body: some View {
        NavigationView {
            List {
                // Source selection
                Section {
                    Button("📁 Choose Source") {
                        showSourceDialog = true
                    }
                    .confirmationDialog(
                        "Select Data Source",
                        isPresented: $showSourceDialog,
                        titleVisibility: .visible
                    ) {
                        ForEach(DataSourceOption.allCases) { option in
                            Button(option.rawValue) {
                                selectedSource = option
                            }
                        }
                    }
                }
                // JD section
                if !viewModel.jd.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Job Description")
                                .font(.headline)
                            Text(viewModel.jd)
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 8)
                    }
                }
                // Error section
                if let error = viewModel.errorMessage {
                    Section {
                        Text("⚠️ \(error)")
                            .foregroundColor(.red)
                    }
                }
                // Match results
                if let result = viewModel.result {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            MatchResultDescriptionText(
                                text: result,
                                analyzingText: analyzingText,
                                isLoading: viewModel.isLoading
                            )
                        }
                        .padding(.vertical, 8)
                    }
                }
                // Loading indicator shown at bottom of list
                if viewModel.isLoading && viewModel.result == nil {
                    Section {
                        AnalyzingText(text: analyzingText)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("CV Match Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.black)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView {
                    viewModel.runMatchingFlow()
                }
            }
            .sheet(item: $selectedSource) { source in
                switch source {
                case .sampleData:
                    SampleDataView { sampleData in
                        viewModel.setup(jd: sampleData.jd, cvs: sampleData.cvs)
                        viewModel.runMatchingFlow()
                    }
                case .uploadFiles:
                    Text("🛠️ Real data screen to be implemented")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
