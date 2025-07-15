//
//  ObjectBoxDatabase.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

import Foundation
import ObjectBox

protocol ObjectBoxDatabase {
    func getStore() throws -> Store
}

enum ObjectBoxDatabaseError: Error, LocalizedError {
    case bundleNotSetup
    case storeNotSetup

    var errorDescription: String? {
        switch self {
        case .bundleNotSetup:
            "Object Box: App Bundle is not setup."
        case .storeNotSetup:
            "Object Box: Store is not setup."
        }
    }
}

final class StandardObjectBoxDatabase: ObjectBoxDatabase {
    static let shared = StandardObjectBoxDatabase()

    private var fileManager: FileManager
    private var bundle: Bundle
    private var store: Store?

    private init() {
        self.fileManager = .default
        self.bundle = .main
    }

    func getStore() throws -> Store {
        if let store = store {
            return store
        }
        let bundleID = bundle.bundleIdentifier ?? "DefaultObjectBoxApp"
        let directory = try fileManager
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent(bundleID)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let store = try Store(directoryPath: directory.path)
        self.store = store
        return store
    }

    func set(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    func set(bundle: Bundle) {
        self.bundle = bundle
    }
}
