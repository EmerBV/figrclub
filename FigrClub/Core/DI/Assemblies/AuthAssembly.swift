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
        // Auth State Manager
        container.register(AuthStateManager.self) { resolver in
            let authRepository = resolver.resolve(AuthRepositoryProtocol.self)!
            let tokenManager = resolver.resolve(TokenManager.self)!
            
            return AuthStateManager(authRepository: authRepository, tokenManager: tokenManager)
        }.inObjectScope(.container)
        
        // Auth ViewModel
        container.register(AuthViewModel.self) { resolver in
            let authStateManager = resolver.resolve(AuthStateManager.self)!
            let validationService = resolver.resolve(ValidationServiceProtocol.self)!
            
            return AuthViewModel(authStateManager: authStateManager, validationService: validationService)
        }.inObjectScope(.transient)
    }
}
