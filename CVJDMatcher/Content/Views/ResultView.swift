//
//  ResultView.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 21/7/25.
//

import SwiftUI

struct ResultView: View {
    let text: String
    let isLoading: Bool
    private let cursorTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var showCursor = true
    @State private var displayedText = ""
    @State private var typingIndex = 0
    @State private var typingTimer: Timer? = nil
    @State private var prevText = ""
    @State private var showAnalyzing = false
    @State private var animationQueue: [Character] = []

    var body: some View {
        var attrText = AttributedString(displayedText)
        if isLoading {
            var cursor = AttributedString(" ● Analyzing...")
            cursor.foregroundColor = .gray.opacity(showCursor ? 0.6 : 0.15)
            attrText.append(cursor)
        }
        return Text(attrText)
            .font(.system(size: 14))
            .onChange(of: text) { newText in
                let commonPrefix = prevText.commonPrefix(with: newText)
                let newPart = String(newText.dropFirst(commonPrefix.count))
                typingTimer?.invalidate()
                displayedText = commonPrefix
                typingIndex = 0
                prevText = newText
                if !newPart.isEmpty {
                    animationQueue = Array(newPart)
                    startTypewriterQueue(prefix: commonPrefix)
                }
            }
            .onAppear {
                if displayedText.isEmpty && !text.isEmpty {
                    animationQueue = Array(text)
                    startTypewriterQueue()
                }
            }
            .onReceive(cursorTimer) { _ in
                showCursor.toggle()
            }
    }

    private func startTypewriterQueue(prefix: String = "") {
        typingTimer?.invalidate()
        displayedText = prefix
        guard !animationQueue.isEmpty else { return }
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if !animationQueue.isEmpty {
                displayedText += String(animationQueue.removeFirst())
            } else {
                timer.invalidate()
                typingTimer = nil
            }
        }
    }
}
