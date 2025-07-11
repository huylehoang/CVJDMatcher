//
//  ContentView.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 30/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var charIndexMap: [UUID: Int] = [:]

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
                ForEach(viewModel.matchResults) { matchResult in
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            MatchResultDescriptionText(
                                text: matchResult.resultDesciption,
                                isLoading: viewModel.isLoading
                            )
                        }
                        .padding(.vertical, 8)
                    }
                }
                // Loading indicator shown at bottom of list
                if viewModel.isLoading && viewModel.matchResults.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text("Analyzing...")
                                .font(.system(size: 14))
                            Spacer()
                        }
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

struct MatchResultDescriptionText: View {
    private let text: String
    private let isLoading: Bool
    private let cursorTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var showCursor = true
    @State private var flash = false

    init(text: String, isLoading: Bool = true) {
        self.text = text
        self.isLoading = isLoading
    }

    var body: some View {
        var attrText = AttributedString(text)
        attrText.foregroundColor = .primary
        if isLoading {
            var cursor = AttributedString(" ● Analyzing...")
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

#Preview {
    ContentView()
}
