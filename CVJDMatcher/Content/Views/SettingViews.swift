//
//  SettingViews.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 21/7/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var ragServiceType = StandardAppEnvironment.shared.ragServiceType
    @State private var embeddingServiceType = StandardAppEnvironment.shared.embeddingServiceType
    @State private var llmServiceType = StandardAppEnvironment.shared.llmServiceType
    @State private var promptServiceType = StandardAppEnvironment.shared.promptServiceType

    let onApply: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("RAG Service")
                        .font(.system(size: 18, weight: .bold))
                ) {
                    Picker("Type", selection: $ragServiceType) {
                        ForEach(RAGServiceType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(
                    header: Text("Embedding Service")
                        .font(.system(size: 18, weight: .bold))
                ) {
                    Picker("Model", selection: $embeddingServiceType) {
                        ForEach(EmbeddingServiceType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(
                    header: Text("LLM Service")
                        .font(.system(size: 18, weight: .bold))
                ) {
                    Picker("Model", selection: $llmServiceType) {
                        ForEach(LLMServiceType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(
                    header: Text("Prompt Service")
                        .font(.system(size: 18, weight: .bold))
                ) {
                    Picker("Type", selection: $promptServiceType) {
                        ForEach(PromptServiceType.allCases, id: \.self) {
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
                        StandardAppEnvironment.shared.set(ragServiceType: ragServiceType)
                        StandardAppEnvironment.shared.set(
                            embeddingServiceType: embeddingServiceType
                        )
                        StandardAppEnvironment.shared.set(llmServiceType: llmServiceType)
                        StandardAppEnvironment.shared.set(promptServiceType: promptServiceType)
                        dismiss()
                        onApply()
                    }
                }
            }
        }
    }
}
