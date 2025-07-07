//
//  StorageManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol StorageManagerProtocol {
    func save<T: Codable>(_ object: T, key: String) throws
    func load<T: Codable>(_ type: T.Type, key: String) throws -> T?
    func delete(key: String) throws
}

final class StorageManager: StorageManagerProtocol {
    func save<T: Codable>(_ object: T, key: String) throws {
        // Implementación temporal
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) throws -> T? {
        // Implementación temporal
        return nil
    }
    
    func delete(key: String) throws {
        // Implementación temporal
    }
}
