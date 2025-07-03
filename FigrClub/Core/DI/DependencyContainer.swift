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
        registerCoreServices()
        registerManagers()
        registerRepositories()
        registerUseCases()
        registerViewModels()
        
        Logger.shared.info("Dependency container configured successfully", category: "di")
    }
}

// MARK: - Core Services Registration
private extension DependencyContainer {
    
    func registerCoreServices() {
        // Singletons
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
    }
}

// MARK: - Managers Registration
private extension DependencyContainer {
    
    func registerManagers() {
        container.register(AuthManagerProtocol.self) { resolver in
            AuthManager(
                apiService: resolver.resolve(APIServiceProtocol.self)!,
                tokenManager: resolver.resolve(TokenManager.self)!
            )
        }.inObjectScope(.container)
        
        container.register(AuthManager.self) { resolver in
            resolver.resolve(AuthManagerProtocol.self) as! AuthManager
        }.inObjectScope(.container)
    }
}

// MARK: - Repositories Registration
private extension DependencyContainer {
    
    func registerRepositories() {
        // Post Repository
        container.register(PostRepository.self) { resolver in
            PostRepositoryImpl(
                apiService: resolver.resolve(APIServiceProtocol.self)!
            )
        }
        
        // User Repository
        container.register(UserRepository.self) { resolver in
            UserRepositoryImpl(
                apiService: resolver.resolve(APIServiceProtocol.self)!
            )
        }
        
        // Marketplace Repository
        container.register(MarketplaceRepository.self) { resolver in
            MarketplaceRepositoryImpl(
                apiService: resolver.resolve(APIServiceProtocol.self)!
            )
        }
        
        // Notification Repository
        container.register(NotificationRepository.self) { resolver in
            NotificationRepositoryImpl(
                apiService: resolver.resolve(APIServiceProtocol.self)!
            )
        }
        
        // Category Repository
        container.register(CategoryRepository.self) { resolver in
            CategoryRepositoryImpl(
                apiService: resolver.resolve(APIServiceProtocol.self)!
            )
        }
        
        // Auth Repository
        container.register(AuthRepository.self) { resolver in
            AuthRepositoryImpl(
                apiService: resolver.resolve(APIServiceProtocol.self)!
            )
        }
    }
}

// MARK: - ViewModels Registration
extension DependencyContainer {
    func registerViewModels() {
        // Login ViewModel
        container.register(LoginViewModel.self) { resolver in
            let viewModel = LoginViewModel()
            return viewModel
        }
        
        // Register ViewModel
        container.register(RegisterViewModel.self) { resolver in
            let authManager = resolver.resolve(AuthManager.self)
            let viewModel = RegisterViewModel(authManager: authManager)
            return viewModel
        }
        
        // Feed ViewModel
        container.register(FeedViewModel.self) { resolver in
            let viewModel = FeedViewModel()
            return viewModel
        }
        
        // Marketplace ViewModel
        container.register(MarketplaceViewModel.self) { resolver in
            let viewModel = MarketplaceViewModel()
            return viewModel
        }
        
        // Notifications ViewModel
        container.register(NotificationsViewModel.self) { resolver in
            let viewModel = NotificationsViewModel()
            return viewModel
        }
        
        // Profile ViewModel
        container.register(ProfileViewModel.self) { resolver in
            let viewModel = ProfileViewModel()
            return viewModel
        }
        
        // Create Post ViewModel
        container.register(CreatePostViewModel.self) { resolver in
            let createPostUseCase = resolver.resolve(CreatePostUseCase.self)!
            let uploadImageUseCase = resolver.resolve(UploadImageUseCase.self)!
            let viewModel = CreatePostViewModel(
                createPostUseCase: createPostUseCase,
                uploadImageUseCase: uploadImageUseCase
            )
            return viewModel
        }
    }
}

// MARK: - Use Cases Registration
private extension DependencyContainer {
    
    func registerUseCases() {
        // Post Use Cases
        container.register(LoadPostsUseCase.self) { resolver in
            LoadPostsUseCaseImpl(
                repository: resolver.resolve(PostRepository.self)!
            )
        }
        
        container.register(LoadUserPostsUseCase.self) { resolver in
            LoadUserPostsUseCaseImpl(
                repository: resolver.resolve(PostRepository.self)!
            )
        }
        
        container.register(CreatePostUseCase.self) { resolver in
            CreatePostUseCaseImpl(
                repository: resolver.resolve(PostRepository.self)!
            )
        }
        
        container.register(TogglePostLikeUseCase.self) { resolver in
            TogglePostLikeUseCaseImpl(
                repository: resolver.resolve(PostRepository.self)!
            )
        }
        
        // User Use Cases
        container.register(LoadUserProfileUseCase.self) { resolver in
            LoadUserProfileUseCaseImpl(
                userRepository: resolver.resolve(UserRepository.self)!
            )
        }
        
        container.register(ToggleFollowUserUseCase.self) { resolver in
            ToggleFollowUserUseCaseImpl(
                repository: resolver.resolve(UserRepository.self)!
            )
        }
        
        // Marketplace Use Cases
        container.register(LoadMarketplaceItemsUseCase.self) { resolver in
            LoadMarketplaceItemsUseCaseImpl(
                repository: resolver.resolve(MarketplaceRepository.self)!
            )
        }
        
        container.register(LoadCategoriesUseCase.self) { resolver in
            LoadCategoriesUseCaseImpl(
                repository: resolver.resolve(CategoryRepository.self)!
            )
        }
        
        // Notification Use Cases
        container.register(LoadNotificationsUseCase.self) { resolver in
            LoadNotificationsUseCaseImpl(
                repository: resolver.resolve(NotificationRepository.self)!
            )
        }
        
        container.register(MarkNotificationAsReadUseCase.self) { resolver in
            MarkNotificationAsReadUseCaseImpl(
                repository: resolver.resolve(NotificationRepository.self)!
            )
        }
        
        // Auth Use Cases
        container.register(LoginUseCase.self) { resolver in
            LoginUseCaseImpl(
                authRepository: resolver.resolve(AuthRepository.self)!,
                userRepository: resolver.resolve(UserRepository.self)!,
                tokenManager: resolver.resolve(TokenManager.self)!
            )
        }
        
        container.register(RegisterUseCase.self) { resolver in
            RegisterUseCaseImpl(
                authRepository: resolver.resolve(AuthRepository.self)!,
                userRepository: resolver.resolve(UserRepository.self)!,
                tokenManager: resolver.resolve(TokenManager.self)!
            )
        }
    }
}

// MARK: - Resolver Methods
extension DependencyContainer {
    
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
}

// MARK: - Factory Methods (MainActor-safe creation)
extension DependencyContainer {
    
    @MainActor
    func makeLoginViewModel() -> LoginViewModel {
        return resolve(LoginViewModel.self)
    }
    
    @MainActor
    func makeRegisterViewModel() -> RegisterViewModel {
        return resolve(RegisterViewModel.self)
    }
    
    @MainActor
    func makeFeedViewModel() -> FeedViewModel {
        return resolve(FeedViewModel.self)
    }
    
    @MainActor
    func makeMarketplaceViewModel() -> MarketplaceViewModel {
        return resolve(MarketplaceViewModel.self)
    }
    
    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        return resolve(ProfileViewModel.self)
    }
    
    @MainActor
    func makeNotificationsViewModel() -> NotificationsViewModel {
        return resolve(NotificationsViewModel.self)
    }
    
    @MainActor
    func makeCreatePostViewModel() -> CreatePostViewModel {
        return resolve(CreatePostViewModel.self)
    }
}

// MARK: - Environment Setup
extension DependencyContainer {
    
    /// Configure container for testing environment
    func configureForTesting() {
        // Remove all existing registrations
        container.removeAll()
        
        // Register mock services for testing
        // This will be implemented when adding tests
        Logger.shared.info("Container configured for testing", category: "di")
    }
    
    /// Configure container for preview environment
    func configureForPreviews() {
        // This can be used for SwiftUI previews with mock data
        Logger.shared.info("Container configured for previews", category: "di")
    }
}

// MARK: - SwiftUI Environment Integration
extension View {
    func dependencyInjection() -> some View {
        self.environmentObject(DependencyContainer.shared.resolve(AuthManager.self))
    }
}
