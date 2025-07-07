//
//  RepositoryAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class RepositoryAssembly: Assembly {
    func assemble(container: Container) {
        // Auth Repository
        container.register(AuthRepositoryProtocol.self) { resolver in
            let authService = resolver.resolve(AuthServiceProtocol.self)!
            let tokenManager = resolver.resolve(TokenManager.self)!
            let secureStorage = resolver.resolve(SecureStorageProtocol.self)!
            
            return AuthRepository(
                authService: authService,
                tokenManager: tokenManager,
                secureStorage: secureStorage
            )
        }.inObjectScope(.container)
    }
}
