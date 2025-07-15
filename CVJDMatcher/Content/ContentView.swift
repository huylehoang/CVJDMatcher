//
//  ContentView.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showSettings = false
    private let analyzingText = " ● Analyzing..."

    var body: some View {
        NavigationView {
            List {
                // JD section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Job Description")
                            .font(.headline)
                        Text(viewModel.jd)
                            .font(.system(size: 14))
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
            .onAppear {
                viewModel.runMatchingFlow()
            }
        }
    }
}

struct AnalyzingText: View {
    let text: String
    private let cursorTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var showCursor = true

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.gray.opacity(showCursor ? 0.6 : 0.15))
            .onReceive(cursorTimer) { _ in
                showCursor.toggle()
            }
    }
}

struct MatchResultDescriptionText: View {
    let text: String
    let analyzingText: String
    let isLoading: Bool
    private let cursorTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var showCursor = true
    @State private var flash = false

    var body: some View {
        var attrText = AttributedString(text)
        attrText.foregroundColor = .primary
        if isLoading {
            var cursor = AttributedString(analyzingText)
            cursor.foregroundColor = .gray.opacity(showCursor ? 0.6 : 0.15)
            attrText.append(cursor)
        }
        return Text(attrText)
            .opacity(flash ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: flash)
            .font(.system(size: 14))
            .onAppear {
                flash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    flash = false
                }
            }
            .onReceive(cursorTimer) { _ in
                showCursor.toggle()
            }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedRAG = AppEnvironment.shared.ragServiceType
    @State private var selectedLLM = AppEnvironment.shared.llmServiceType
    @State private var selectedEmbedding = AppEnvironment.shared.embeddingServiceType

    let onApply: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("RAG Service")
                        .font(.system(size: 18, weight: .bold))
                ) {
                    Picker("Type", selection: $selectedRAG) {
                        ForEach(RAGServiceType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(
                    header: Text("LLM Service")
                        .font(.system(size: 18, weight: .bold))
                ) {
                    Picker("Model", selection: $selectedLLM) {
                        ForEach(LLMServiceType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(
                    header: Text("Embedding Service")
                        .font(.system(size: 18, weight: .bold))
                ) {
                    Picker("Model", selection: $selectedEmbedding) {
                        ForEach(EmbeddingServiceType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        AppEnvironment.shared.set(embeddingServiceType: selectedEmbedding)
                        AppEnvironment.shared.set(llmServiceType: selectedLLM)
                        dismiss()
                        onApply()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
