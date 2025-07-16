//
//  ViewModelAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class ViewModelAssembly: Assembly {
    func assemble(container: Container) {
        
        // MARK: - State Managers
        
        // App State Manager (Central state management) - MainActor
        container.register(AppStateManager.self) { resolver in
            let authStateManager = resolver.resolve(AuthStateManager.self)!
            // Create on MainActor
            return MainActor.assumeIsolated {
                AppStateManager(authStateManager: authStateManager)
            }
        }.inObjectScope(.container)
        
        // MARK: - Error Handling
        
        // Global Error Handler (Centralized error management) - MainActor
        container.register(GlobalErrorHandler.self) { _ in
            // Create on MainActor
            return MainActor.assumeIsolated {
                GlobalErrorHandler()
            }
        }.inObjectScope(.container)
        
        // MARK: - ViewModels
        
        // Auth ViewModel - MainActor
        container.register(AuthViewModel.self) { resolver in
            let authStateManager = resolver.resolve(AuthStateManager.self)!
            let validationService = resolver.resolve(ValidationServiceProtocol.self)!
            
            // Create on MainActor
            return MainActor.assumeIsolated {
                AuthViewModel(authStateManager: authStateManager, validationService: validationService)
            }
        }.inObjectScope(.transient)
        
        // MARK: - Validation Managers
        // FormValidationManager instances are created directly in ViewModels
        
        // MARK: - Future ViewModels
        // ViewModels for specific features will be registered here when implemented
        
        Logger.debug("✅ ViewModelAssembly: All ViewModels and state managers registered")
    }
}

