//
//  ConsoleAppLogger.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 19/7/25.
//

import Foundation

struct ConsoleAppLogger: AppLogger {
    func log(_ message: String, level: AppLogLevel = .info) {
        print("----------------------------------------------------")
        print("\(level.rawValue):\n\(message)")
        print("----------------------------------------------------\n")
    }

    func logTokenizer(_ tokenizer: Any) {
        log("Tokenizer: \(String(describing: tokenizer))", level: .info)
    }

    func logPrompt(_ prompt: String) {
        log(prompt, level: .prompt)
    }

    func logPrediction(_ prediction: String, index: Int? = nil, time: TimeInterval? = nil) {
        var msg = prediction
        if let index, let time {
            msg = "(Index \(index), <\(time)s>): \(prediction)"
        }
        log(msg, level: .prediction)
    }

    func logRunMatchingFlow() {
        log("Run Matching Flow", level: .info)
    }

    func logResult(_ result: String) {
        log(result, level: .result)
    }

    func logError(_ error: Error) {
        log(error.localizedDescription, level: .error)
    }

    func logCancelled() {
        log("Task was cancelled", level: .warning)
    }

    func logInferenceTimeout() {
        log("Inference timed out", level: .warning)
    }
}
