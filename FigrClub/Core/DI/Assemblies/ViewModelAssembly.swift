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
        
        // Legacy Error Handler (for backward compatibility) - MainActor
        container.register(ErrorHandler.self) { _ in
            // Create on MainActor
            return MainActor.assumeIsolated {
                ErrorHandler()
            }
        }.inObjectScope(.transient)
        
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
        
        // Form Validation Manager Factory - MainActor
        container.register(FormValidationManager.self) { _ in
            // Create on MainActor
            return MainActor.assumeIsolated {
                FormValidationManager()
            }
        }.inObjectScope(.transient)
        
        // MARK: - Coordinators (Future ViewModels)
        
        // Note: Coordinators will be registered here when we create specific ViewModels
        // for each feature (Feed, Marketplace, etc.)
        
        // Feed ViewModel (when implemented)
        // container.register(FeedViewModel.self) { resolver in
        //     let postService = resolver.resolve(PostServiceProtocol.self)!
        //     let appStateManager = resolver.resolve(AppStateManager.self)!
        //     let errorHandler = resolver.resolve(GlobalErrorHandler.self)!
        //     return FeedViewModel(
        //         postService: postService,
        //         appStateManager: appStateManager,
        //         errorHandler: errorHandler
        //     )
        // }.inObjectScope(.transient)
        
        // Profile ViewModel (when implemented)
        // container.register(ProfileViewModel.self) { resolver in
        //     let userService = resolver.resolve(UserServiceProtocol.self)!
        //     let appStateManager = resolver.resolve(AppStateManager.self)!
        //     let errorHandler = resolver.resolve(GlobalErrorHandler.self)!
        //     return ProfileViewModel(
        //         userService: userService,
        //         appStateManager: appStateManager,
        //         errorHandler: errorHandler
        //     )
        // }.inObjectScope(.transient)
        
        Logger.debug("✅ ViewModelAssembly: All ViewModels and state managers registered")
    }
}

