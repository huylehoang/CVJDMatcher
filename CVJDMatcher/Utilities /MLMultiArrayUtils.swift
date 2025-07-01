//
//  MLMultiArrayUtils.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 1/7/25.
//

import CoreML

/// Utility class for converting Swift arrays into Core ML–compatible `MLMultiArray`.
enum MLMultiArrayUtils {
    /// Converts an array of `Int` into an MLMultiArray with a custom shape.
    /// Use this for inputs that require rank-2 (e.g., `[1, maxLength]`).
    /// - Parameters:
    ///   - values: The flattened input array.
    ///   - shape: The desired shape (e.g., `[1, 128]`).
    /// - Returns: An MLMultiArray with the given shape and type `.int32`.
    static func int32(from values: [Int], shape: [Int]) throws -> MLMultiArray {
        let totalCount = shape.reduce(1, *)
        guard values.count == totalCount else {
            let description = "Values count \(values.count) does not match shape \(shape)"
            throw NSError(
                domain: "MLMultiArrayUtils",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }
        let mlArray = try MLMultiArray(shape: shape.map { NSNumber(value: $0) }, dataType: .int32)
        for (i, value) in values.enumerated() {
            mlArray[i] = NSNumber(value: value)
        }
        return mlArray
    }
}
