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

struct MatchingInputData: Identifiable {
    let id = UUID()
    let jd: String
    let cvs: [String]
}

struct ContentView: View {
    private let appEnvironment = StandardAppEnvironment.shared
    @StateObject private var viewModel = ContentViewModel()
    @State private var showSettings = false
    @State private var showDataSourceDialog = false
    @State private var showDataSourceSheet = false
    @State private var showJDPreview = false
    @State private var selectedDataSourceOption: DataSourceOption?
    private let jdCharacterLimit = 1000

    var body: some View {
        NavigationView {
            List {
                // Source selection
                Section {
                    Button("📁 Choose Source") {
                        showDataSourceDialog = true
                    }
                    .confirmationDialog(
                        "Select Data Source",
                        isPresented: $showDataSourceDialog,
                        titleVisibility: .visible
                    ) {
                        ForEach(DataSourceOption.allCases) { option in
                            Button(option.rawValue) {
                                selectedDataSourceOption = option
                                showDataSourceSheet = true
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
                            if viewModel.jd.count > jdCharacterLimit {
                                Button(action: {
                                    showJDPreview = true
                                }) {
                                    Text("✅ JD loaded (\(viewModel.jd.count) characters)")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text(viewModel.jd)
                                    .font(.system(size: 14))
                            }
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
                            ResultView(text: result, isLoading: viewModel.isLoading)
                        }
                        .padding(.vertical, 8)
                    }
                }
                // Loading indicator shown at bottom of list
                if viewModel.isLoading && viewModel.result == nil {
                    Section {
                        ResultView(text: "", isLoading: viewModel.isLoading)
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
                            .foregroundStyle(.gray)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView {
                    if selectedDataSourceOption == .uploadFiles &&
                        appEnvironment.llmServiceType != .firebase_gemini_1_5_flash {
                        viewModel.setup(jd: "", cvs: [])
                    }
                    viewModel.runMatchingFlow()
                }
            }
            .sheet(isPresented: $showDataSourceSheet) {
                if let source = selectedDataSourceOption {
                    switch source {
                    case .sampleData:
                        SampleDataView { data in
                            viewModel.setup(jd: data.jd, cvs: data.cvs)
                            viewModel.runMatchingFlow()
                        }
                    case .uploadFiles:
                        switch appEnvironment.llmServiceType {
                        case .firebase_gemini_1_5_flash:
                            UploadFilesView { data in
                                viewModel.setup(jd: data.jd, cvs: data.cvs)
                                viewModel.runMatchingFlow()
                            }
                        default:
                            Text("Should use Upload Files feature for Firebase AI")
                        }
                    }
                }
            }
            .sheet(isPresented: $showJDPreview) {
                ScrollView {
                    Text(viewModel.jd)
                        .padding()
                }
                .navigationTitle("JD Preview")
            }
        }
    }
}

#Preview {
    ContentView()
}
