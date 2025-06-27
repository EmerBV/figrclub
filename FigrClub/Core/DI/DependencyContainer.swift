//
//  DependencyContainer.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Swinject
import SwinjectAutoregistration

final class DependencyContainer {
    static let shared = DependencyContainer()
    
    let container = Container()
    
    private init() {
        setupDependencies()
    }
    
    private func setupDependencies() {
        // MARK: - Core Services
        container.register(APIServiceProtocol.self) { _ in
            APIService.shared
        }.inObjectScope(.container)
        
        container.register(TokenManager.self) { _ in
            TokenManager.shared
        }.inObjectScope(.container)
        
        // MARK: - Managers
        container.register(AuthManagerProtocol.self) { resolver in
            // Create AuthManager on MainActor
            let apiService = resolver.resolve(APIServiceProtocol.self)!
            let tokenManager = resolver.resolve(TokenManager.self)!
            return AuthManager(apiService: apiService, tokenManager: tokenManager)
        }.inObjectScope(.container)
        
        container.register(AuthManager.self) { resolver in
            resolver.resolve(AuthManagerProtocol.self) as! AuthManager
        }.inObjectScope(.container)
        
        // MARK: - ViewModels
        // Authentication
        container.register(LoginViewModel.self) { resolver in
            let authManager = resolver.resolve(AuthManager.self)!
            return LoginViewModel(authManager: authManager)
        }
        
        container.register(RegisterViewModel.self) { resolver in
            let authManager = resolver.resolve(AuthManager.self)!
            return RegisterViewModel(authManager: authManager)
        }
        
        // Future ViewModels
        // container.autoregister(FeedViewModel.self, initializer: FeedViewModel.init)
        // container.autoregister(MarketplaceViewModel.self, initializer: MarketplaceViewModel.init)
        // container.autoregister(ProfileViewModel.self, initializer: ProfileViewModel.init)
    }
    
    // MARK: - Resolver Methods
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolved = container.resolve(type) else {
            fatalError("Could not resolve \(type)")
        }
        return resolved
    }
    
    func resolve<T, Arg>(_ type: T.Type, argument: Arg) -> T {
        guard let resolved = container.resolve(type, argument: argument) else {
            fatalError("Could not resolve \(type) with argument \(Arg.self)")
        }
        return resolved
    }
}

// MARK: - Dependency Injection Property Wrapper
@propertyWrapper
struct Injected<T> {
    private let dependency: T
    
    init() {
        self.dependency = DependencyContainer.shared.resolve(T.self)
    }
    
    var wrappedValue: T {
        return dependency
    }
}
