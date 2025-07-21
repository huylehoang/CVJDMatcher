//
//  MatchResultDescriptionText.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 21/7/25.
//

import SwiftUI

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
            .onChange(of: text) { _ in
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
