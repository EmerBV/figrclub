//
//  StorageAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class StorageAssembly: Assembly {
    func assemble(container: Container) {
        // Keychain Manager
        container.register(KeychainManagerProtocol.self) { _ in
            KeychainManager()
        }.inObjectScope(.container)
        
        // Secure Storage
        container.register(SecureStorageProtocol.self) { r in
            let keychainManager = r.resolve(KeychainManagerProtocol.self)!
            return SecureStorage(keychainManager: keychainManager)
        }.inObjectScope(.container)
        
        // User Defaults Manager
        container.register(UserDefaultsManagerProtocol.self) { _ in
            UserDefaultsManager()
        }.inObjectScope(.container)
        
        // Auth Manager
        container.register(AuthManager.self) { r in
            let tokenManager = r.resolve(TokenManager.self)!
            return AuthManager(tokenManager: tokenManager)
        }.inObjectScope(.container)
    }
}
