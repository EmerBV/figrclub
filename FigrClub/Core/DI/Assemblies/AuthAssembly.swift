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
        
        // OPCIÓN 1: Factory con async initialization
        // Auth Manager - usando factory que maneja MainActor
        container.register(AuthManager.self) { r in
            let authRepository = r.resolve(AuthRepositoryProtocol.self)!
            let tokenManager = r.resolve(TokenManager.self)!
            
            // Crear AuthManager de forma sincrónica - necesitamos remover @MainActor del init
            return AuthManager(authRepository: authRepository, tokenManager: tokenManager)
        }.inObjectScope(.container)
        
        // Auth ViewModel - similar approach
        container.register(AuthViewModel.self) { r in
            let authManager = r.resolve(AuthManager.self)!
            let validationService = r.resolve(ValidationServiceProtocol.self)!
            
            // Crear AuthViewModel de forma sincrónica - necesitamos remover @MainActor del init
            return AuthViewModel(authManager: authManager, validationService: validationService)
        }.inObjectScope(.transient)
    }
}
