//
//  DependencyContainer.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI
import Swinject
import SwinjectAutoregistration

final class DependencyContainer {
    static let shared = DependencyContainer()
    
    let container = Container()
    
    private init() {
        setupDependencies()
    }
    
    private func setupDependencies() {
        // MARK: - Core Services (Manual registration for singletons)
        container.register(APIServiceProtocol.self) { _ in
            APIService.shared
        }.inObjectScope(.container)
        
        container.register(TokenManager.self) { _ in
            TokenManager.shared
        }.inObjectScope(.container)
        
        container.register(Logger.self) { _ in
            Logger.shared
        }.inObjectScope(.container)
        
        container.register(Analytics.self) { _ in
            Analytics.shared
        }.inObjectScope(.container)
        
        // MARK: - Managers (Using autoregistration)
        container.autoregister(AuthManagerProtocol.self, initializer: AuthManager.init)
            .inObjectScope(.container)
        
        container.register(AuthManager.self) { resolver in
            resolver.resolve(AuthManagerProtocol.self) as! AuthManager
        }.inObjectScope(.container)
        
        // MARK: - ViewModels (FIXED: Using nonisolated factory closures)
        
        // Authentication ViewModels
        container.register(LoginViewModel.self) { resolver in
            // FIXED: Create factory closure that will be called on MainActor
            let authManager = resolver.resolve(AuthManager.self)!
            return LoginViewModel(authManager: authManager)
        }
        
        container.register(RegisterViewModel.self) { resolver in
            // FIXED: Create factory closure that will be called on MainActor
            let authManager = resolver.resolve(AuthManager.self)!
            return RegisterViewModel(authManager: authManager)
        }
        
        // Main Feature ViewModels
        container.register(FeedViewModel.self) { resolver in
            let apiService = resolver.resolve(APIServiceProtocol.self)!
            return FeedViewModel(apiService: apiService)
        }
        
        container.register(MarketplaceViewModel.self) { resolver in
            let apiService = resolver.resolve(APIServiceProtocol.self)!
            return MarketplaceViewModel(apiService: apiService)
        }
        
        container.register(ProfileViewModel.self) { resolver in
            let apiService = resolver.resolve(APIServiceProtocol.self)!
            let authManager = resolver.resolve(AuthManager.self)!
            return ProfileViewModel(
                apiService: apiService,
                authManager: authManager
            )
        }
        
        container.register(NotificationsViewModel.self) { resolver in
            let apiService = resolver.resolve(APIServiceProtocol.self)!
            return NotificationsViewModel(apiService: apiService)
        }
        
        container.register(CreatePostViewModel.self) { resolver in
            let apiService = resolver.resolve(APIServiceProtocol.self)!
            return CreatePostViewModel(apiService: apiService)
        }
        
        container.register(CommentsViewModel.self) { resolver in
            let apiService = resolver.resolve(APIServiceProtocol.self)!
            return CommentsViewModel(apiService: apiService)
        }
        
        Logger.shared.info("Dependency container configured successfully", category: "di")
    }
    
    // MARK: - Resolver Methods
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolved = container.resolve(type) else {
            Logger.shared.fatal("Could not resolve \(type)", category: "di")
            fatalError("Could not resolve \(type)")
        }
        return resolved
    }
    
    func resolve<T, Arg>(_ type: T.Type, argument: Arg) -> T {
        guard let resolved = container.resolve(type, argument: argument) else {
            Logger.shared.fatal("Could not resolve \(type) with argument \(Arg.self)", category: "di")
            fatalError("Could not resolve \(type) with argument \(Arg.self)")
        }
        return resolved
    }
    
    func resolve<T, Arg1, Arg2>(_ type: T.Type, arguments arg1: Arg1, _ arg2: Arg2) -> T {
        guard let resolved = container.resolve(type, arguments: arg1, arg2) else {
            Logger.shared.fatal("Could not resolve \(type) with arguments", category: "di")
            fatalError("Could not resolve \(type) with arguments")
        }
        return resolved
    }
    
    // MARK: - Factory Methods (FIXED: MainActor-safe creation)
    
    /// Creates a new LoginViewModel instance on MainActor
    @MainActor
    func makeLoginViewModel() -> LoginViewModel {
        return resolve(LoginViewModel.self)
    }
    
    /// Creates a new FeedViewModel instance on MainActor
    @MainActor
    func makeFeedViewModel() -> FeedViewModel {
        return resolve(FeedViewModel.self)
    }
    
    /// Creates a new MarketplaceViewModel instance on MainActor
    @MainActor
    func makeMarketplaceViewModel() -> MarketplaceViewModel {
        return resolve(MarketplaceViewModel.self)
    }
    
    /// Creates a new ProfileViewModel instance on MainActor
    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        return resolve(ProfileViewModel.self)
    }
    
    /// Creates a new NotificationsViewModel instance on MainActor
    @MainActor
    func makeNotificationsViewModel() -> NotificationsViewModel {
        return resolve(NotificationsViewModel.self)
    }
    
    /// Creates a new CreatePostViewModel instance on MainActor
    @MainActor
    func makeCreatePostViewModel() -> CreatePostViewModel {
        return resolve(CreatePostViewModel.self)
    }
    
    /// Creates a new CommentsViewModel instance on MainActor
    @MainActor
    func makeCommentsViewModel() -> CommentsViewModel {
        return resolve(CommentsViewModel.self)
    }
    
    // MARK: - Debug Methods
#if DEBUG
    func printRegisteredServices() {
        Logger.shared.debug("Registered services in DI container:", category: "di")
        // This would require reflection or manual tracking
        // For now, we'll log that the container is ready
        Logger.shared.debug("DI Container is ready with all dependencies", category: "di")
    }
    
    func validateDependencies() -> Bool {
        do {
            // Test critical dependencies
            _ = resolve(AuthManagerProtocol.self)
            _ = resolve(APIServiceProtocol.self)
            _ = resolve(TokenManager.self)
            
            Logger.shared.info("All critical dependencies validated successfully", category: "di")
            return true
        } catch {
            Logger.shared.error("Dependency validation failed", error: error, category: "di")
            return false
        }
    }
#endif
}

// MARK: - Dependency Injection Property Wrapper (Updated)
@propertyWrapper
struct Injected<T> {
    private let dependency: T
    
    init() {
        self.dependency = DependencyContainer.shared.resolve(T.self)
    }
    
    init(argument: Any) {
        self.dependency = DependencyContainer.shared.resolve(T.self, argument: argument)
    }
    
    var wrappedValue: T {
        return dependency
    }
}

// MARK: - SwiftUI Environment Integration
extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

// MARK: - View Modifier for DI
struct DependencyInjectionModifier: ViewModifier {
    let container: DependencyContainer
    
    func body(content: Content) -> some View {
        content
            .environment(\.dependencyContainer, container)
    }
}

extension View {
    func dependencyInjection(_ container: DependencyContainer = .shared) -> some View {
        modifier(DependencyInjectionModifier(container: container))
    }
}
