//
//  AnalyzingText.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 21/7/25.
//

import SwiftUI

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
