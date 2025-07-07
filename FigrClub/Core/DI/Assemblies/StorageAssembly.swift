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
        // Token Manager
        container.register(TokenManager.self) { _ in
            TokenManager()
        }.inObjectScope(.container)
        
        // Auth Manager
        container.register(AuthManager.self) { r in
            let tokenManager = r.resolve(TokenManager.self)!
            return AuthManager(tokenManager: tokenManager)
        }.inObjectScope(.container)
        
        // Storage Manager
        container.register(StorageManagerProtocol.self) { _ in
            StorageManager()
        }.inObjectScope(.container)
    }
}
