//
//  AppLogger.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 19/7/25.
//

import Foundation

enum AppLogLevel: String {
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "🛑 ERROR"
    case prompt = "⚡️ PROMPT"
    case prediction = "🦄 Prediction"
    case result = "✅ RESULT"
}

protocol AppLogger {
    func log(_ message: String, level: AppLogLevel)
    func logTokenizer(_ tokenizer: Any)
    func logPrompt(_ prompt: String)
    func logPrediction(_ prediction: String, index: Int?, time: TimeInterval?)
    func logRunMatchingFlow()
    func logResult(_ result: String)
    func logError(_ error: Error)
    func logCancelled()
    func logInferenceTimeout()
}

extension AppLogger {
    func logPrediction(_ prediction: String) {
        logPrediction(prediction, index: nil, time: nil)
    }
}
