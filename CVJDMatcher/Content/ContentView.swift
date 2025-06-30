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
                if let error = viewModel.errorMessage {
                    Section {
                        Text("⚠️ \(error)")
                            .foregroundColor(.red)
                    }
                }
                ForEach(viewModel.matchResults) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.cv)
                            .font(.headline)
                        Text(result.scoreString)
                        Text(result.explanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
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
