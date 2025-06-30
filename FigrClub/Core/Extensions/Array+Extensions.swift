//
//  Array+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

extension Array {
    /// Safely access array elements
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// Remove duplicates while preserving order
    func removingDuplicates<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { element in
            let key = element[keyPath: keyPath]
            return seen.insert(key).inserted
        }
    }
}

