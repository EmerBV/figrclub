//
//  RepositoryProtocols.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation
import Combine

// MARK: - Post Repository Protocol
protocol PostRepository {
    func getPosts(page: Int, size: Int) async throws -> PaginatedResponse<Post>
    func getUserPosts(userId: Int, page: Int, size: Int) async throws -> PaginatedResponse<Post>
    func getPost(id: Int) async throws -> Post
    func createPost(_ request: CreatePostRequest) async throws -> Post
    func likePost(id: Int) async throws -> Post
    func unlikePost(id: Int) async throws -> Post
}

// MARK: - User Repository Protocol
protocol UserRepository {
    func getCurrentUser() async throws -> User
    func getUser(id: Int) async throws -> User
    func updateUser(id: Int, updateData: UpdateUserRequest) async throws -> User
    func getUserStats(id: Int) async throws -> UserStats
    func followUser(id: Int) async throws -> Void
    func unfollowUser(id: Int) async throws -> Void
    func getFollowers(userId: Int, page: Int, size: Int) async throws -> PaginatedResponse<User>
    func getFollowing(userId: Int, page: Int, size: Int) async throws -> PaginatedResponse<User>
}

// MARK: - Marketplace Repository Protocol
protocol MarketplaceRepository {
    func getItems(page: Int, size: Int) async throws -> PaginatedResponse<MarketplaceItem>
    func getItem(id: Int) async throws -> MarketplaceItem
    func createItem(_ request: CreateMarketplaceItemRequest) async throws -> MarketplaceItem
    func updateItem(id: Int, request: UpdateMarketplaceItemRequest) async throws -> MarketplaceItem
    func deleteItem(id: Int) async throws -> Void
    func searchItems(query: String, page: Int, size: Int) async throws -> PaginatedResponse<MarketplaceItem>
    func getItemsByCategory(categoryId: Int, page: Int, size: Int) async throws -> PaginatedResponse<MarketplaceItem>
}

// MARK: - Notification Repository Protocol
protocol NotificationRepository {
    func getNotifications(page: Int, size: Int) async throws -> PaginatedResponse<AppNotification>
    func markAsRead(id: Int) async throws -> AppNotification
    func markAllAsRead() async throws -> Void
    func getUnreadCount() async throws -> Int
    func deleteNotification(id: Int) async throws -> Void
}

// MARK: - Category Repository Protocol
protocol CategoryRepository {
    func getCategories() async throws -> [Category]
    func getCategory(id: Int) async throws -> Category
}

// MARK: - Authentication Repository Protocol
protocol AuthRepository {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(_ request: RegisterRequest) async throws -> User
    func logout() async throws -> Void
    func refreshToken() async throws -> AuthResponse
    func forgotPassword(email: String) async throws -> Void
    func resetPassword(token: String, newPassword: String) async throws -> Void
}

