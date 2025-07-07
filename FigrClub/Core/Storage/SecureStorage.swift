//
//  SecureStorage.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import KeychainAccess

protocol SecureStorageProtocol: Sendable {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func get<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func remove(forKey key: String) throws
    func contains(key: String) -> Bool
}

final class SecureStorage: SecureStorageProtocol, @unchecked Sendable {
    private let keychain: Keychain
    
    init() {
        self.keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "com.emerbv.FigrClub")
            .accessibility(.whenUnlockedThisDeviceOnly)
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(object)
        try keychain.set(data, key: key)
        Logger.debug("SecureStorage: Saved object for key: \(key)")
    }
    
    func get<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try keychain.getData(key) else {
            Logger.debug("SecureStorage: No data found for key: \(key)")
            return nil
        }
        
        let object = try JSONDecoder().decode(type, from: data)
        Logger.debug("SecureStorage: Retrieved object for key: \(key)")
        return object
    }
    
    func remove(forKey key: String) throws {
        try keychain.remove(key)
        Logger.debug("SecureStorage: Removed object for key: \(key)")
    }
    
    func contains(key: String) -> Bool {
        do {
            return try keychain.contains(key)
        } catch {
            Logger.error("SecureStorage: Error checking key existence: \(error)")
            return false
        }
    }
}
