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
        container.register(AuthRepositoryProtocol.self) { r in
            let authService = r.resolve(AuthServiceProtocol.self)!
            let tokenManager = r.resolve(TokenManager.self)!
            let secureStorage = r.resolve(SecureStorageProtocol.self)!
            return AuthRepository(
                authService: authService,
                tokenManager: tokenManager,
                secureStorage: secureStorage
            )
        }.inObjectScope(.container)
    }
}
