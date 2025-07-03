//
//  RepositoryImplementations.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation
import Combine

// MARK: - Remote Post Repository
final class RemotePostRepository: PostRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func getPosts(page: Int, size: Int) async throws -> PaginatedResponse<Post> {
        return try await apiService
            .request(endpoint: .publicFeed(page: page, size: size), body: nil)
            .async()
    }
    
    func getUserPosts(userId: Int, page: Int, size: Int) async throws -> PaginatedResponse<Post> {
        return try await apiService
            .request(endpoint: .userPosts(userId: userId, page: page, size: size), body: nil)
            .async()
    }
    
    func getPost(id: Int) async throws -> Post {
        return try await apiService
            .request(endpoint: .getPost(id), body: nil)
            .async()
    }
    
    func createPost(_ request: CreatePostRequest) async throws -> Post {
        return try await apiService
            .request(endpoint: .createPost, body: request)
            .async()
    }
    
    func likePost(id: Int) async throws -> Post {
        return try await apiService
            .request(endpoint: .likePost(id), body: nil)
            .async()
    }
    
    func unlikePost(id: Int) async throws -> Post {
        return try await apiService
            .request(endpoint: .unlikePost(id), body: nil)
            .async()
    }
}

// MARK: - Remote User Repository
final class RemoteUserRepository: UserRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func getCurrentUser() async throws -> User {
        return try await apiService
            .request(endpoint: .getCurrentUser, body: nil)
            .async()
    }
    
    func getUser(id: Int) async throws -> User {
        return try await apiService
            .request(endpoint: .getUserById(id), body: nil)
            .async()
    }
    
    func updateUser(id: Int, updateData: UpdateUserRequest) async throws -> User {
        return try await apiService
            .request(endpoint: .updateUser(id), body: updateData)
            .async()
    }
    
    func getUserStats(id: Int) async throws -> UserStats {
        return try await apiService
            .request(endpoint: .getUserStats(id), body: nil)
            .async()
    }
    
    func followUser(id: Int) async throws -> Void {
        let _: EmptyResponse = try await apiService
            .request(endpoint: .followUser(id), body: nil)
            .async()
    }
    
    func unfollowUser(id: Int) async throws -> Void {
        let _: EmptyResponse = try await apiService
            .request(endpoint: .unfollowUser(id), body: nil)
            .async()
    }
    
    func getFollowers(userId: Int, page: Int, size: Int) async throws -> PaginatedResponse<User> {
        return try await apiService
            .request(endpoint: .getFollowers(userId: userId, page: page, size: size), body: nil)
            .async()
    }
    
    func getFollowing(userId: Int, page: Int, size: Int) async throws -> PaginatedResponse<User> {
        return try await apiService
            .request(endpoint: .getFollowing(userId: userId, page: page, size: size), body: nil)
            .async()
    }
}

// MARK: - Remote Marketplace Repository
final class RemoteMarketplaceRepository: MarketplaceRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func getItems(page: Int, size: Int) async throws -> PaginatedResponse<MarketplaceItem> {
        return try await apiService
            .request(endpoint: .marketplaceItems(page: page, size: size), body: nil)
            .async()
    }
    
    func getItem(id: Int) async throws -> MarketplaceItem {
        return try await apiService
            .request(endpoint: .getMarketplaceItem(id), body: nil)
            .async()
    }
    
    func createItem(_ request: CreateMarketplaceItemRequest) async throws -> MarketplaceItem {
        return try await apiService
            .request(endpoint: .createMarketplaceItem, body: request)
            .async()
    }
    
    func updateItem(id: Int, request: UpdateMarketplaceItemRequest) async throws -> MarketplaceItem {
        return try await apiService
            .request(endpoint: .updateMarketplaceItem(id), body: request)
            .async()
    }
    
    func deleteItem(id: Int) async throws -> Void {
        let _: EmptyResponse = try await apiService
            .request(endpoint: .deleteMarketplaceItem(id), body: nil)
            .async()
    }
    
    func searchItems(query: String, page: Int, size: Int) async throws -> PaginatedResponse<MarketplaceItem> {
        return try await apiService
            .request(endpoint: .searchMarketplaceItems(query: query, page: page, size: size), body: nil)
            .async()
    }
    
    func getItemsByCategory(categoryId: Int, page: Int, size: Int) async throws -> PaginatedResponse<MarketplaceItem> {
        return try await apiService
            .request(endpoint: .getMarketplaceItemsByCategory(categoryId: categoryId, page: page, size: size), body: nil)
            .async()
    }
}

// MARK: - Remote Notification Repository
final class RemoteNotificationRepository: NotificationRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func getNotifications(page: Int, size: Int) async throws -> PaginatedResponse<AppNotification> {
        return try await apiService
            .request(endpoint: .getNotifications(page: page, size: size), body: nil)
            .async()
    }
    
    func markAsRead(id: Int) async throws -> AppNotification {
        return try await apiService
            .request(endpoint: .markNotificationAsRead(id), body: nil)
            .async()
    }
    
    func markAllAsRead() async throws -> Void {
        let _: EmptyResponse = try await apiService
            .request(endpoint: .markAllNotificationsAsRead, body: nil)
            .async()
    }
    
    func getUnreadCount() async throws -> Int {
        let response: UnreadCountResponse = try await apiService
            .request(endpoint: .getUnreadNotificationsCount, body: nil)
            .async()
        return response.count
    }
    
    func deleteNotification(id: Int) async throws -> Void {
        let _: EmptyResponse = try await apiService
            .request(endpoint: .deleteNotification(id), body: nil)
            .async()
    }
}

// MARK: - Remote Category Repository
final class RemoteCategoryRepository: CategoryRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func getCategories() async throws -> [Category] {
        return try await apiService
            .request(endpoint: .getCategories, body: nil)
            .async()
    }
    
    func getCategory(id: Int) async throws -> Category {
        return try await apiService
            .request(endpoint: .getCategory(id), body: nil)
            .async()
    }
}

// MARK: - Remote Auth Repository
final class RemoteAuthRepository: AuthRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let loginRequest = LoginRequest(email: email, password: password)
        return try await apiService
            .request(endpoint: .login, body: loginRequest)
            .async()
    }
    
    func register(_ request: RegisterRequest) async throws -> User {
        return try await apiService
            .request(endpoint: .register, body: request)
            .async()
    }
    
    func logout() async throws -> Void {
        let _: EmptyResponse = try await apiService
            .request(endpoint: .logout, body: nil)
            .async()
    }
    
    func refreshToken() async throws -> AuthResponse {
        return try await apiService
            .request(endpoint: .refreshToken, body: nil)
            .async()
    }
    
    func forgotPassword(email: String) async throws -> Void {
        let request = ForgotPasswordRequest(email: email)
        let _: EmptyResponse = try await apiService
            .request(endpoint: .forgotPassword, body: request)
            .async()
    }
    
    func resetPassword(token: String, newPassword: String) async throws -> Void {
        let request = ResetPasswordRequest(token: token, newPassword: newPassword)
        let _: EmptyResponse = try await apiService
            .request(endpoint: .resetPassword, body: request)
            .async()
    }
}

// MARK: - Post Repository Implementation
final class PostRepositoryImpl: PostRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func getPublicFeed(page: Int, size: Int) -> AnyPublisher<PageResponse<Post>, APIError> {
        apiService.request(endpoint: .publicFeed(page: page, size: size), body: nil)
    }
    
    func getUserPosts(userId: Int, page: Int, size: Int) -> AnyPublisher<PageResponse<Post>, APIError> {
        apiService.request(endpoint: .userPosts(userId: userId, page: page, size: size), body: nil)
    }
    
    func getPost(by id: Int) -> AnyPublisher<Post, APIError> {
        apiService.request(endpoint: .getPost(id), body: nil)
    }
    
    func createPost(_ request: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        apiService.request(endpoint: .createPost, body: request)
    }
    
    func updatePost(id: Int, request: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        apiService.request(endpoint: .updatePost(id), body: request)
    }
    
    func deletePost(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .deletePost(id), body: nil)
    }
    
    func likePost(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .likePost(id), body: nil)
    }
    
    func unlikePost(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .unlikePost(id), body: nil)
    }
}

// MARK: - User Repository Implementation
final class UserRepositoryImpl: UserRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func getCurrentUser() -> AnyPublisher<User, APIError> {
        apiService.request(endpoint: .getCurrentUser, body: nil)
    }
    
    func getUser(by id: Int) -> AnyPublisher<User, APIError> {
        apiService.request(endpoint: .getUserById(id), body: nil)
    }
    
    func updateUser(id: Int, request: UpdateUserRequest) -> AnyPublisher<User, APIError> {
        apiService.request(endpoint: .updateUser(id), body: request)
    }
    
    func getUserStats(userId: Int) -> AnyPublisher<UserStats, APIError> {
        apiService.request(endpoint: .getUserStats(userId), body: nil)
    }
    
    func getFollowers(userId: Int, page: Int, size: Int) -> AnyPublisher<PageResponse<User>, APIError> {
        apiService.request(endpoint: .getFollowers(userId: userId, page: page, size: size), body: nil)
    }
    
    func getFollowing(userId: Int, page: Int, size: Int) -> AnyPublisher<PageResponse<User>, APIError> {
        apiService.request(endpoint: .getFollowing(userId: userId, page: page, size: size), body: nil)
    }
    
    func followUser(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .followUser(id), body: nil)
    }
    
    func unfollowUser(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .unfollowUser(id), body: nil)
    }
}

// MARK: - Marketplace Repository Implementation
final class MarketplaceRepositoryImpl: MarketplaceRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func getMarketplaceItems(page: Int, size: Int) -> AnyPublisher<PageResponse<MarketplaceItem>, APIError> {
        apiService.request(endpoint: .marketplaceItems(page: page, size: size), body: nil)
    }
    
    func getMarketplaceItem(by id: Int) -> AnyPublisher<MarketplaceItem, APIError> {
        apiService.request(endpoint: .getMarketplaceItem(id), body: nil)
    }
    
    func createMarketplaceItem(_ request: CreateMarketplaceItemRequest) -> AnyPublisher<MarketplaceItem, APIError> {
        apiService.request(endpoint: .createMarketplaceItem, body: request)
    }
    
    func updateMarketplaceItem(id: Int, request: UpdateMarketplaceItemRequest) -> AnyPublisher<MarketplaceItem, APIError> {
        apiService.request(endpoint: .updateMarketplaceItem(id), body: request)
    }
    
    func deleteMarketplaceItem(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .deleteMarketplaceItem(id), body: nil)
    }
    
    func searchMarketplaceItems(query: String, page: Int, size: Int) -> AnyPublisher<PageResponse<MarketplaceItem>, APIError> {
        apiService.request(endpoint: .searchMarketplaceItems(query: query, page: page, size: size), body: nil)
    }
    
    func getMarketplaceItemsByCategory(categoryId: Int, page: Int, size: Int) -> AnyPublisher<PageResponse<MarketplaceItem>, APIError> {
        apiService.request(endpoint: .getMarketplaceItemsByCategory(categoryId: categoryId, page: page, size: size), body: nil)
    }
    
    func favoriteMarketplaceItem(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .favoriteMarketplaceItem(id), body: nil)
    }
    
    func unfavoriteMarketplaceItem(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .unfavoriteMarketplaceItem(id), body: nil)
    }
}

// MARK: - Notification Repository Implementation
final class NotificationRepositoryImpl: NotificationRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func getNotifications(page: Int, size: Int) -> AnyPublisher<PageResponse<NotificationItem>, APIError> {
        apiService.request(endpoint: .getNotifications(page: page, size: size), body: nil)
    }
    
    func markNotificationAsRead(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .markNotificationAsRead(id), body: nil)
    }
    
    func markAllNotificationsAsRead() -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .markAllNotificationsAsRead, body: nil)
    }
    
    func deleteNotification(id: Int) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .deleteNotification(id), body: nil)
    }
    
    func getNotificationPreferences() -> AnyPublisher<NotificationPreferences, APIError> {
        apiService.request(endpoint: .getNotificationPreferences, body: nil)
    }
    
    func updateNotificationPreferences(_ request: UpdateNotificationPreferencesRequest) -> AnyPublisher<NotificationPreferences, APIError> {
        apiService.request(endpoint: .updateNotificationPreferences, body: request)
    }
}

// MARK: - Category Repository Implementation
final class CategoryRepositoryImpl: CategoryRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func getCategories() -> AnyPublisher<[Category], APIError> {
        apiService.request(endpoint: .getCategories, body: nil)
    }
    
    func getCategory(by id: Int) -> AnyPublisher<Category, APIError> {
        apiService.request(endpoint: .getCategory(id), body: nil)
    }
}

// MARK: - Auth Repository Implementation
final class AuthRepositoryImpl: AuthRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func login(_ request: LoginRequest) -> AnyPublisher<AuthResponse, APIError> {
        apiService.request(endpoint: .login, body: request)
    }
    
    func register(_ request: RegisterRequest) -> AnyPublisher<AuthResponse, APIError> {
        apiService.request(endpoint: .register, body: request)
    }
    
    func logout() -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .logout, body: nil)
    }
    
    func refreshToken(_ request: RefreshTokenRequest) -> AnyPublisher<AuthResponse, APIError> {
        apiService.request(endpoint: .refreshToken, body: request)
    }
    
    func forgotPassword(_ request: ForgotPasswordRequest) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .forgotPassword, body: request)
    }
    
    func resetPassword(_ request: ResetPasswordRequest) -> AnyPublisher<Void, APIError> {
        apiService.request(endpoint: .resetPassword, body: request)
    }
}




