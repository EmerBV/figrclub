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
        
        // Auth Manager - Swift 6 compatible registration usando inicializador nonisolated
        container.register(AuthManager.self) { resolver in
            let authRepository = resolver.resolve(AuthRepositoryProtocol.self)!
            let tokenManager = resolver.resolve(TokenManager.self)!
            
            // Crear AuthManager directamente con inicializador nonisolated
            return AuthManager(authRepository: authRepository, tokenManager: tokenManager)
        }.inObjectScope(.container)
        
        // Auth ViewModel - Swift 6 compatible registration usando inicializador nonisolated
        container.register(AuthViewModel.self) { resolver in
            let authManager = resolver.resolve(AuthManager.self)!
            let validationService = resolver.resolve(ValidationServiceProtocol.self)!
            
            // Crear AuthViewModel directamente con inicializador nonisolated
            return AuthViewModel(authManager: authManager, validationService: validationService)
        }.inObjectScope(.transient)
    }
}
