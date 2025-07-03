//
//  UseCases.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation

// MARK: - Base Use Case Protocol
protocol UseCase {
    associatedtype Input
    associatedtype Output
    
    func execute(_ input: Input) async throws -> Output
}

// MARK: - Post Use Cases

protocol LoadPostsUseCase: UseCase where Input == LoadPostsInput, Output == PaginatedResponse<Post> {}

struct LoadPostsInput {
    let page: Int
    let size: Int
}

final class LoadPostsUseCaseImpl: LoadPostsUseCase {
    private let repository: PostRepository
    
    init(repository: PostRepository) {
        self.repository = repository
    }
    
    func execute(_ input: LoadPostsInput) async throws -> PaginatedResponse<Post> {
        Logger.shared.info("Loading posts - Page: \(input.page), Size: \(input.size)", category: "usecase")
        
        let result = try await repository.getPosts(page: input.page, size: input.size)
        
        Logger.shared.info("Loaded \(result.content.count) posts successfully", category: "usecase")
        Analytics.shared.logEvent("posts_loaded", parameters: [
            "count": result.content.count,
            "page": input.page
        ])
        
        return result
    }
}

// MARK: - Load User Posts Use Case

protocol LoadUserPostsUseCase: UseCase where Input == LoadUserPostsInput, Output == PaginatedResponse<Post> {}

struct LoadUserPostsInput {
    let userId: Int
    let page: Int
    let size: Int
}

final class LoadUserPostsUseCaseImpl: LoadUserPostsUseCase {
    private let repository: PostRepository
    
    init(repository: PostRepository) {
        self.repository = repository
    }
    
    func execute(_ input: LoadUserPostsInput) async throws -> PaginatedResponse<Post> {
        Logger.shared.info("Loading user posts - UserId: \(input.userId), Page: \(input.page)", category: "usecase")
        
        let result = try await repository.getUserPosts(userId: input.userId, page: input.page, size: input.size)
        
        Logger.shared.info("Loaded \(result.content.count) user posts successfully", category: "usecase")
        
        return result
    }
}

// MARK: - Create Post Use Case

protocol CreatePostUseCase: UseCase where Input == CreatePostRequest, Output == Post {}

final class CreatePostUseCaseImpl: CreatePostUseCase {
    private let repository: PostRepository
    
    init(repository: PostRepository) {
        self.repository = repository
    }
    
    func execute(_ input: CreatePostRequest) async throws -> Post {
        Logger.shared.info("Creating new post", category: "usecase")
        
        // Validate input
        guard !input.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw UseCaseError.invalidInput("Post content cannot be empty")
        }
        
        let result = try await repository.createPost(input)
        
        Logger.shared.info("Post created successfully with ID: \(result.id)", category: "usecase")
        Analytics.shared.logEvent("post_created", parameters: [
            "post_id": result.id,
            "has_images": !(input.imageUrls?.isEmpty ?? true)
        ])
        
        return result
    }
}

// MARK: - Like/Unlike Post Use Cases

protocol TogglePostLikeUseCase: UseCase where Input == TogglePostLikeInput, Output == Post {}

struct TogglePostLikeInput {
    let postId: Int
    let isCurrentlyLiked: Bool
}

final class TogglePostLikeUseCaseImpl: TogglePostLikeUseCase {
    private let repository: PostRepository
    
    init(repository: PostRepository) {
        self.repository = repository
    }
    
    func execute(_ input: TogglePostLikeInput) async throws -> Post {
        let action = input.isCurrentlyLiked ? "unlike" : "like"
        Logger.shared.info("Toggling post \(action) for post: \(input.postId)", category: "usecase")
        
        let result = try await input.isCurrentlyLiked
        ? repository.unlikePost(id: input.postId)
        : repository.likePost(id: input.postId)
        
        Analytics.shared.logEvent("post_\(action)", parameters: [
            "post_id": input.postId
        ])
        
        return result
    }
}

// MARK: - User Use Cases

protocol LoadUserProfileUseCase: UseCase where Input == Int, Output == (User, UserStats) {}

final class LoadUserProfileUseCaseImpl: LoadUserProfileUseCase {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    func execute(_ input: Int) async throws -> (User, UserStats) {
        Logger.shared.info("Loading user profile for ID: \(input)", category: "usecase")
        
        async let user = userRepository.getUser(id: input)
        async let stats = userRepository.getUserStats(id: input)
        
        let result = try await (user, stats)
        
        Logger.shared.info("User profile loaded successfully", category: "usecase")
        
        return result
    }
}

// MARK: - Follow/Unfollow Use Case

protocol ToggleFollowUserUseCase: UseCase where Input == ToggleFollowInput, Output == Void {}

struct ToggleFollowInput {
    let userId: Int
    let isCurrentlyFollowing: Bool
}

final class ToggleFollowUserUseCaseImpl: ToggleFollowUserUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(_ input: ToggleFollowInput) async throws -> Void {
        let action = input.isCurrentlyFollowing ? "unfollow" : "follow"
        Logger.shared.info("Toggling \(action) for user: \(input.userId)", category: "usecase")
        
        if input.isCurrentlyFollowing {
            try await repository.unfollowUser(id: input.userId)
        } else {
            try await repository.followUser(id: input.userId)
        }
        
        Analytics.shared.logEvent("user_\(action)", parameters: [
            "target_user_id": input.userId
        ])
    }
}

// MARK: - Marketplace Use Cases

protocol LoadMarketplaceItemsUseCase: UseCase where Input == LoadMarketplaceItemsInput, Output == PaginatedResponse<MarketplaceItem> {}

struct LoadMarketplaceItemsInput {
    let page: Int
    let size: Int
    let categoryId: Int?
    let searchQuery: String?
}

final class LoadMarketplaceItemsUseCaseImpl: LoadMarketplaceItemsUseCase {
    private let repository: MarketplaceRepository
    
    init(repository: MarketplaceRepository) {
        self.repository = repository
    }
    
    func execute(_ input: LoadMarketplaceItemsInput) async throws -> PaginatedResponse<MarketplaceItem> {
        Logger.shared.info("Loading marketplace items - Page: \(input.page)", category: "usecase")
        
        let result: PaginatedResponse<MarketplaceItem>
        
        if let searchQuery = input.searchQuery, !searchQuery.isEmpty {
            result = try await repository.searchItems(query: searchQuery, page: input.page, size: input.size)
        } else if let categoryId = input.categoryId {
            result = try await repository.getItemsByCategory(categoryId: categoryId, page: input.page, size: input.size)
        } else {
            result = try await repository.getItems(page: input.page, size: input.size)
        }
        
        Logger.shared.info("Loaded \(result.content.count) marketplace items", category: "usecase")
        
        return result
    }
}

// MARK: - Authentication Use Cases

protocol LoginUseCase: UseCase where Input == LoginInput, Output == (AuthResponse, User) {}

struct LoginInput {
    let email: String
    let password: String
}

final class LoginUseCaseImpl: LoginUseCase {
    private let authRepository: AuthRepository
    private let userRepository: UserRepository
    private let tokenManager: TokenManager
    
    init(
        authRepository: AuthRepository,
        userRepository: UserRepository,
        tokenManager: TokenManager
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.tokenManager = tokenManager
    }
    
    func execute(_ input: LoginInput) async throws -> (AuthResponse, User) {
        Logger.shared.info("Attempting login for email: \(input.email)", category: "usecase")
        
        // Validate input
        guard !input.email.isEmpty, !input.password.isEmpty else {
            throw UseCaseError.invalidInput("Email and password are required")
        }
        
        guard input.email.contains("@") else {
            throw UseCaseError.invalidInput("Invalid email format")
        }
        
        let authResponse = try await authRepository.login(email: input.email, password: input.password)
        
        // Save tokens
        tokenManager.saveTokens(
            accessToken: authResponse.authToken.token,
            refreshToken: nil,
            userId: authResponse.userId
        )
        
        // Get user details
        let user = try await userRepository.getUser(id: authResponse.userId)
        
        Logger.shared.info("Login successful for user: \(user.id)", category: "usecase")
        Analytics.shared.logEvent("user_login", parameters: [
            "user_id": user.id,
            "user_type": user.userType.rawValue
        ])
        
        return (authResponse, user)
    }
}

// MARK: - Register Use Case

protocol RegisterUseCase: UseCase where Input == RegisterRequest, Output == User {}

final class RegisterUseCaseImpl: RegisterUseCase {
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute(_ input: RegisterRequest) async throws -> User {
        Logger.shared.info("Attempting registration for email: \(input.email)", category: "usecase")
        
        // Validate input
        try validateRegistrationInput(input)
        
        let user = try await authRepository.register(input)
        
        Logger.shared.info("Registration successful for user: \(user.id)", category: "usecase")
        Analytics.shared.logEvent("user_register", parameters: [
            "user_id": user.id,
            "user_type": user.userType.rawValue
        ])
        
        return user
    }
    
    private func validateRegistrationInput(_ input: RegisterRequest) throws {
        guard !input.email.isEmpty else {
            throw UseCaseError.invalidInput("Email is required")
        }
        
        guard input.email.contains("@") else {
            throw UseCaseError.invalidInput("Invalid email format")
        }
        
        guard !input.firstName.isEmpty else {
            throw UseCaseError.invalidInput("First name is required")
        }
        
        guard !input.lastName.isEmpty else {
            throw UseCaseError.invalidInput("Last name is required")
        }
        
        guard !input.username.isEmpty else {
            throw UseCaseError.invalidInput("Username is required")
        }
        
        guard input.password.count >= 8 else {
            throw UseCaseError.invalidInput("Password must be at least 8 characters")
        }
    }
}

// MARK: - Notification Use Cases

protocol LoadNotificationsUseCase: UseCase where Input == LoadNotificationsInput, Output == PaginatedResponse<AppNotification> {}

struct LoadNotificationsInput {
    let page: Int
    let size: Int
}

final class LoadNotificationsUseCaseImpl: LoadNotificationsUseCase {
    private let repository: NotificationRepository
    
    init(repository: NotificationRepository) {
        self.repository = repository
    }
    
    func execute(_ input: LoadNotificationsInput) async throws -> PaginatedResponse<AppNotification> {
        Logger.shared.info("Loading notifications - Page: \(input.page)", category: "usecase")
        
        let result = try await repository.getNotifications(page: input.page, size: input.size)
        
        Logger.shared.info("Loaded \(result.content.count) notifications", category: "usecase")
        
        return result
    }
}

// MARK: - Mark Notification as Read Use Case

protocol MarkNotificationAsReadUseCase: UseCase where Input == Int, Output == AppNotification {}

final class MarkNotificationAsReadUseCaseImpl: MarkNotificationAsReadUseCase {
    private let repository: NotificationRepository
    
    init(repository: NotificationRepository) {
        self.repository = repository
    }
    
    func execute(_ input: Int) async throws -> AppNotification {
        Logger.shared.info("Marking notification as read: \(input)", category: "usecase")
        
        let result = try await repository.markAsRead(id: input)
        
        Analytics.shared.logEvent("notification_read", parameters: [
            "notification_id": input
        ])
        
        return result
    }
}

// MARK: - Load Categories Use Case

protocol LoadCategoriesUseCase: UseCase where Input == Void, Output == [Category] {}

final class LoadCategoriesUseCaseImpl: LoadCategoriesUseCase {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func execute(_ input: Void) async throws -> [Category] {
        Logger.shared.info("Loading categories", category: "usecase")
        
        let result = try await repository.getCategories()
        
        Logger.shared.info("Loaded \(result.count) categories", category: "usecase")
        
        return result
    }
}

// MARK: - Use Case Factory

final class UseCaseFactory {
    
    // MARK: - Repositories
    private let postRepository: PostRepository
    private let userRepository: UserRepository
    private let marketplaceRepository: MarketplaceRepository
    private let notificationRepository: NotificationRepository
    private let categoryRepository: CategoryRepository
    private let authRepository: AuthRepository
    private let tokenManager: TokenManager
    
    init(
        postRepository: PostRepository,
        userRepository: UserRepository,
        marketplaceRepository: MarketplaceRepository,
        notificationRepository: NotificationRepository,
        categoryRepository: CategoryRepository,
        authRepository: AuthRepository,
        tokenManager: TokenManager
    ) {
        self.postRepository = postRepository
        self.userRepository = userRepository
        self.marketplaceRepository = marketplaceRepository
        self.notificationRepository = notificationRepository
        self.categoryRepository = categoryRepository
        self.authRepository = authRepository
        self.tokenManager = tokenManager
    }
    
    // MARK: - Post Use Cases
    func makeLoadPostsUseCase() -> LoadPostsUseCase {
        return LoadPostsUseCaseImpl(repository: postRepository)
    }
    
    func makeLoadUserPostsUseCase() -> LoadUserPostsUseCase {
        return LoadUserPostsUseCaseImpl(repository: postRepository)
    }
    
    func makeCreatePostUseCase() -> CreatePostUseCase {
        return CreatePostUseCaseImpl(repository: postRepository)
    }
    
    func makeTogglePostLikeUseCase() -> TogglePostLikeUseCase {
        return TogglePostLikeUseCaseImpl(repository: postRepository)
    }
    
    // MARK: - User Use Cases
    func makeLoadUserProfileUseCase() -> LoadUserProfileUseCase {
        return LoadUserProfileUseCaseImpl(userRepository: userRepository)
    }
    
    func makeToggleFollowUserUseCase() -> ToggleFollowUserUseCase {
        return ToggleFollowUserUseCaseImpl(repository: userRepository)
    }
    
    // MARK: - Marketplace Use Cases
    func makeLoadMarketplaceItemsUseCase() -> LoadMarketplaceItemsUseCase {
        return LoadMarketplaceItemsUseCaseImpl(repository: marketplaceRepository)
    }
    
    // MARK: - Auth Use Cases
    func makeLoginUseCase() -> LoginUseCase {
        return LoginUseCaseImpl(
            authRepository: authRepository,
            userRepository: userRepository,
            tokenManager: tokenManager
        )
    }
    
    func makeRegisterUseCase() -> RegisterUseCase {
        return RegisterUseCaseImpl(authRepository: authRepository)
    }
    
    // MARK: - Notification Use Cases
    func makeLoadNotificationsUseCase() -> LoadNotificationsUseCase {
        return LoadNotificationsUseCaseImpl(repository: notificationRepository)
    }
    
    func makeMarkNotificationAsReadUseCase() -> MarkNotificationAsReadUseCase {
        return MarkNotificationAsReadUseCaseImpl(repository: notificationRepository)
    }
    
    // MARK: - Category Use Cases
    func makeLoadCategoriesUseCase() -> LoadCategoriesUseCase {
        return LoadCategoriesUseCaseImpl(repository: categoryRepository)
    }
}
