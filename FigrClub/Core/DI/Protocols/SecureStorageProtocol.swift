//
//  SecureStorageProtocol.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

protocol SecureStorageProtocol {
    func store<T: Codable>(_ object: T, for key: String) throws
    func retrieve<T: Codable>(_ type: T.Type, for key: String) throws -> T
    func delete(for key: String) throws
}

final class SecureStorage: SecureStorageProtocol {
    private let keychainManager: KeychainManagerProtocol
    
    init(keychainManager: KeychainManagerProtocol) {
        self.keychainManager = keychainManager
    }
    
    func store<T: Codable>(_ object: T, for key: String) throws {
        let data = try JSONEncoder().encode(object)
        try keychainManager.save(key: key, data: data)
    }
    
    func retrieve<T: Codable>(_ type: T.Type, for key: String) throws -> T {
        let data = try keychainManager.load(key: key)
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(for key: String) throws {
        try keychainManager.delete(key: key)
    }
}
