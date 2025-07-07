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
            TokenManager.shared
        }.inObjectScope(.container)
        
        // Secure Storage
        container.register(SecureStorageProtocol.self) { _ in
            SecureStorage()
        }.inObjectScope(.container)
    }
}
