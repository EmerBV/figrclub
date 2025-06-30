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
        
        /*
        // MARK: - Repositories (Using autoregistration)
        container.autoregister(UserRepositoryProtocol.self, initializer: UserRepository.init)
            .inObjectScope(.container)
        
        container.autoregister(PostRepositoryProtocol.self, initializer: PostRepository.init)
            .inObjectScope(.container)
        
        container.autoregister(MarketplaceRepositoryProtocol.self, initializer: MarketplaceRepository.init)
            .inObjectScope(.container)
        
        container.autoregister(NotificationRepositoryProtocol.self, initializer: NotificationRepository.init)
            .inObjectScope(.container)
        
        // MARK: - Services (Using autoregistration)
        container.autoregister(NotificationService.self, initializer: NotificationService.init)
            .inObjectScope(.container)
        
        container.autoregister(ImageService.self, initializer: ImageService.init)
            .inObjectScope(.container)
        
        container.autoregister(LocationService.self, initializer: LocationService.init)
            .inObjectScope(.container)
         */
        
        // MARK: - ViewModels (Using autoregistration - new instance each time)
        
        // Authentication ViewModels
        container.autoregister(LoginViewModel.self, initializer: LoginViewModel.init)
        container.autoregister(RegisterViewModel.self, initializer: RegisterViewModel.init)
        
        /*
        // Main Feature ViewModels
        container.autoregister(FeedViewModel.self, initializer: FeedViewModel.init)
        container.autoregister(MarketplaceViewModel.self, initializer: MarketplaceViewModel.init)
        container.autoregister(ProfileViewModel.self, initializer: ProfileViewModel.init)
        container.autoregister(ChatViewModel.self, initializer: ChatViewModel.init)
        
        // Detail ViewModels
        container.autoregister(PostDetailViewModel.self, initializer: PostDetailViewModel.init)
        container.autoregister(ItemDetailViewModel.self, initializer: ItemDetailViewModel.init)
        container.autoregister(UserProfileViewModel.self, initializer: UserProfileViewModel.init)
        
        // Settings ViewModels
        container.autoregister(SettingsViewModel.self, initializer: SettingsViewModel.init)
        container.autoregister(NotificationSettingsViewModel.self, initializer: NotificationSettingsViewModel.init)
         */
        
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

// MARK: - ViewModels with Autoregistration Examples

// Example of how ViewModels should be structured for autoregistration:

/*
// MARK: - Example Repository (for reference)
protocol UserRepositoryProtocol {
    func getUser(id: Int) async throws -> User
    func updateUser(_ user: User) async throws -> User
}

final class UserRepository: UserRepositoryProtocol {
    private let apiService: APIServiceProtocol
    private let tokenManager: TokenManager
    
    // Constructor that autoregistration will use
    init(apiService: APIServiceProtocol, tokenManager: TokenManager) {
        self.apiService = apiService
        self.tokenManager = tokenManager
    }
    
    func getUser(id: Int) async throws -> User {
        // Implementation
    }
    
    func updateUser(_ user: User) async throws -> User {
        // Implementation
    }
}

// MARK: - Example ViewModel (for reference)
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    
    private let userRepository: UserRepositoryProtocol
    private let authManager: AuthManager
    
    // Constructor that autoregistration will use
    init(userRepository: UserRepositoryProtocol, authManager: AuthManager) {
        self.userRepository = userRepository
        self.authManager = authManager
    }
    
    func loadProfile() async {
        // Implementation
    }
}
*/

// MARK: - Usage Examples
extension DependencyContainer {
    
    // MARK: - Factory Methods (Optional convenience methods)
    
    /// Creates a new LoginViewModel instance
    func makeLoginViewModel() -> LoginViewModel {
        return resolve(LoginViewModel.self)
    }
    
    /*
    /// Creates a new FeedViewModel instance
    func makeFeedViewModel() -> FeedViewModel {
        return resolve(FeedViewModel.self)
    }
    
    /// Creates a PostDetailViewModel with specific post
    func makePostDetailViewModel(post: Post) -> PostDetailViewModel {
        return resolve(PostDetailViewModel.self, argument: post)
    }
     */
    
    // MARK: - SwiftUI View Extensions (for easy DI in Views)
    
    static func configureForSwiftUI() {
        // This can be called from App.swift to ensure container is ready
        _ = shared
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
