//
//  JSONLoader.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 1/7/25.
//

import Foundation

enum JSONLoaderError: Error, LocalizedError {
    case fileNotFound(name: String)
    case invalidData
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Could not find JSON file named: \(name).json"
        case .invalidData:
            return "Data in file is invalid or unreadable."
        case .decodingFailed:
            return "Failed to decode JSON into expected type."
        }
    }
}

enum JSONLoader {
    /// Load vocab dictionary [String: Int] from a JSON file in the bundle.
    static func loadVocab(
        from filename: String,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> [String: Int] {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw JSONLoaderError.fileNotFound(name: filename)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw JSONLoaderError.invalidData
        }
        do {
            return try JSONDecoder().decode([String: Int].self, from: data)
        } catch {
            throw JSONLoaderError.decodingFailed
        }
    }

    /// Load merges list [(String, String)] from a JSON file in the bundle.
    static func loadMerges(
        from filename: String,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> [(String, String)] {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw JSONLoaderError.fileNotFound(name: filename)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw JSONLoaderError.invalidData
        }
        do {
            let rawPairs = try JSONDecoder().decode([[String]].self, from: data)
            return rawPairs.compactMap { $0.count == 2 ? ($0[0], $0[1]) : nil }
        } catch {
            throw JSONLoaderError.decodingFailed
        }
    }

    /// Load and decode a JSON file into a specified Decodable model type.
    static func loadModel<T: Decodable>(
        from filename: String,
        as type: T.Type,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw JSONLoaderError.fileNotFound(name: filename)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw JSONLoaderError.invalidData
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw JSONLoaderError.decodingFailed
        }
    }
}
