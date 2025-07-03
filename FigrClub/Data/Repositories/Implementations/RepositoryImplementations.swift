//
//  RepositoryImplementations.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - Remote Post Repository
final class RemotePostRepository: PostRepository {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func getFeed(page: Int, size: Int) async throws -> PaginatedResponse<Post> {
        return try await apiService
            .request(endpoint: .publicFeed(page: page, size: size), body: nil)
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
    
    // TODO: Define UpdatePostRequest model
    /*
    func updatePost(id: Int, request: UpdatePostRequest) async throws -> Post {
        return try await apiService
            .request(endpoint: .updatePost(id), body: request)
            .async()
    }
    */
    
    func deletePost(id: Int) async throws -> Void {
        let _: EmptyResponse = try await apiService
            .request(endpoint: .deletePost(id), body: nil)
            .async()
    }
    
    func getUserPosts(userId: Int, page: Int, size: Int) async throws -> PaginatedResponse<Post> {
        return try await apiService
            .request(endpoint: .userPosts(userId: userId, page: page, size: size), body: nil)
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

