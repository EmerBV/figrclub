//
//  SecureStorage.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import KeychainAccess

protocol SecureStorageProtocol: Sendable {
    func save<T: Codable>(_ object: T, key: String) throws
    func load<T: Codable>(_ type: T.Type, key: String) throws -> T?
    func delete(key: String) throws
}

final class SecureStorage: SecureStorageProtocol, Sendable {
    private let keychain: Keychain
    
    init() {
        self.keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "com.emerbv.FigrClub")
            .accessibility(.whenUnlockedThisDeviceOnly)
    }
    
    func save<T: Codable>(_ object: T, key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try keychain.set(data, key: key)
        Logger.debug("Object saved to secure storage with key: \(key)")
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) throws -> T? {
        guard let data = try keychain.getData(key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        let object = try decoder.decode(type, from: data)
        Logger.debug("Object loaded from secure storage with key: \(key)")
        return object
    }
    
    func delete(key: String) throws {
        try keychain.remove(key)
        Logger.debug("Object deleted from secure storage with key: \(key)")
    }
}
