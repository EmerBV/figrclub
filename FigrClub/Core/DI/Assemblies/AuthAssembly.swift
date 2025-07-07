//
//  AuthAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class AuthAssembly: Assembly {
    func assemble(container: Container) {
        
        // Auth Manager
        container.register(AuthManager.self) { resolver in
            let authRepository = resolver.resolve(AuthRepositoryProtocol.self)!
            let tokenManager = resolver.resolve(TokenManager.self)!
            
            return AuthManager(authRepository: authRepository, tokenManager: tokenManager)
        }.inObjectScope(.container)
        
        // Auth ViewModel
        container.register(AuthViewModel.self) { resolver in
            let authManager = resolver.resolve(AuthManager.self)!
            let validationService = resolver.resolve(ValidationServiceProtocol.self)!
            
            return AuthViewModel(authManager: authManager, validationService: validationService)
        }.inObjectScope(.transient)
    }
}
