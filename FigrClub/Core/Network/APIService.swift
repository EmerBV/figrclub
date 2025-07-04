//
//  APIService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - API Service Protocol
protocol APIServiceProtocol {
    func request<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable?
    ) -> AnyPublisher<T, APIError>
}

// MARK: - API Service Implementation
final class APIService: APIServiceProtocol {
    static let shared = APIService()
    
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    func request<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable? = nil
    ) -> AnyPublisher<T, APIError> {
        
#if DEBUG
        print("🚀 API Request: \(endpoint.method.rawValue) \(endpoint.path)")
        if let body = body {
            print("📤 Request Body: \(body)")
        }
#endif
        
        // Validar endpoint antes de hacer la petición
        do {
            try endpoint.validateEndpoint()
        } catch {
            return Fail(error: error as? APIError ?? APIError(
                message: "Endpoint validation failed",
                code: "VALIDATION_ERROR"
            ))
            .eraseToAnyPublisher()
        }
        
        return networkManager.request(endpoint: endpoint, body: body)
    }
}

// MARK: - Convenience Extensions
extension APIService {
    
    // MARK: - Authentication
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        let loginRequest = LoginRequest(email: email, password: password)
        return request(endpoint: .login, body: loginRequest)
    }
    
    func register(_ registerRequest: RegisterRequest) -> AnyPublisher<User, APIError> {
        return request(endpoint: .register, body: registerRequest)
    }
    
    func logout() -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .logout, body: nil)
    }
    
    func refreshToken() -> AnyPublisher<AuthResponse, APIError> {
        return request(endpoint: .refreshToken, body: nil)
    }
    
    func forgotPassword(email: String) -> AnyPublisher<EmptyResponse, APIError> {
        let request = ForgotPasswordRequest(email: email)
        return self.request(endpoint: .forgotPassword, body: request)
    }
    
    func resetPassword(token: String, newPassword: String) -> AnyPublisher<EmptyResponse, APIError> {
        let request = ResetPasswordRequest(token: token, newPassword: newPassword)
        return self.request(endpoint: .resetPassword, body: request)
    }
    
    // MARK: - Users
    func getCurrentUser() -> AnyPublisher<User, APIError> {
        return request(endpoint: .getCurrentUser, body: nil)
    }
    
    func getUser(id: Int) -> AnyPublisher<User, APIError> {
        return request(endpoint: .getUserById(id), body: nil)
    }
    
    func updateUser(id: Int, updateData: Codable) -> AnyPublisher<User, APIError> {
        return request(endpoint: .updateUser(id), body: updateData)
    }
    
    func getUserStats(id: Int) -> AnyPublisher<UserStats, APIError> {
        return request(endpoint: .getUserStats(id), body: nil)
    }
    
    func getFollowers(userId: Int, page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<User>, APIError> {
        return request(endpoint: .getFollowers(userId: userId, page: page, size: size), body: nil)
    }
    
    func getFollowing(userId: Int, page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<User>, APIError> {
        return request(endpoint: .getFollowing(userId: userId, page: page, size: size), body: nil)
    }
    
    func followUser(id: Int) -> AnyPublisher<FollowResponse, APIError> {
        return request(endpoint: .followUser(id), body: nil)
    }
    
    func unfollowUser(id: Int) -> AnyPublisher<FollowResponse, APIError> {
        return request(endpoint: .unfollowUser(id), body: nil)
    }
    
    // MARK: - Posts
    func getPublicFeed(page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<Post>, APIError> {
        return request(endpoint: .publicFeed(page: page, size: size), body: nil)
    }
    
    func getUserPosts(userId: Int, page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<Post>, APIError> {
        return request(endpoint: .userPosts(userId: userId, page: page, size: size), body: nil)
    }
    
    func getPost(id: Int) -> AnyPublisher<Post, APIError> {
        return request(endpoint: .getPost(id), body: nil)
    }
    
    func createPost(_ post: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        return request(endpoint: .createPost, body: post)
    }
    
    func updatePost(id: Int, updateData: Codable) -> AnyPublisher<Post, APIError> {
        return request(endpoint: .updatePost(id), body: updateData)
    }
    
    func deletePost(id: Int) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .deletePost(id), body: nil)
    }
    
    func likePost(id: Int) -> AnyPublisher<LikeResponse, APIError> {
        return request(endpoint: .likePost(id), body: nil)
    }
    
    func unlikePost(id: Int) -> AnyPublisher<LikeResponse, APIError> {
        return request(endpoint: .unlikePost(id), body: nil)
    }
    
    // MARK: - Comments
    func getComments(postId: Int, page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<Comment>, APIError> {
        return request(endpoint: .getComments(postId: postId, page: page, size: size), body: nil)
    }
    
    func createComment(_ comment: CreateCommentRequest) -> AnyPublisher<Comment, APIError> {
        return request(endpoint: .createComment, body: comment)
    }
    
    func updateComment(id: Int, updateData: Codable) -> AnyPublisher<Comment, APIError> {
        return request(endpoint: .updateComment(id), body: updateData)
    }
    
    func deleteComment(id: Int) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .deleteComment(id), body: nil)
    }
    
    func likeComment(id: Int) -> AnyPublisher<LikeResponse, APIError> {
        return request(endpoint: .likeComment(id), body: nil)
    }
    
    func unlikeComment(id: Int) -> AnyPublisher<LikeResponse, APIError> {
        return request(endpoint: .unlikeComment(id), body: nil)
    }
    
    // MARK: - Marketplace
    func getMarketplaceItems(page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<MarketplaceItem>, APIError> {
        return request(endpoint: .marketplaceItems(page: page, size: size), body: nil)
    }
    
    func getMarketplaceItem(id: Int) -> AnyPublisher<MarketplaceItem, APIError> {
        return request(endpoint: .getMarketplaceItem(id), body: nil)
    }
    
    func createMarketplaceItem(_ item: CreateMarketplaceItemRequest) -> AnyPublisher<MarketplaceItem, APIError> {
        return request(endpoint: .createMarketplaceItem, body: item)
    }
    
    func updateMarketplaceItem(id: Int, updateData: Codable) -> AnyPublisher<MarketplaceItem, APIError> {
        return request(endpoint: .updateMarketplaceItem(id), body: updateData)
    }
    
    func deleteMarketplaceItem(id: Int) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .deleteMarketplaceItem(id), body: nil)
    }
    
    func searchMarketplaceItems(query: String, page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<MarketplaceItem>, APIError> {
        return request(endpoint: .searchMarketplaceItems(query: query, page: page, size: size), body: nil)
    }
    
    func getMarketplaceItemsByCategory(categoryId: Int, page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<MarketplaceItem>, APIError> {
        return request(endpoint: .getMarketplaceItemsByCategory(categoryId: categoryId, page: page, size: size), body: nil)
    }
    
    func favoriteMarketplaceItem(id: Int) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .favoriteMarketplaceItem(id), body: nil)
    }
    
    func unfavoriteMarketplaceItem(id: Int) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .unfavoriteMarketplaceItem(id), body: nil)
    }
    
    // MARK: - Categories
    func getCategories() -> AnyPublisher<[Category], APIError> {
        return request(endpoint: .getCategories, body: nil)
    }
    
    func getCategory(id: Int) -> AnyPublisher<Category, APIError> {
        return request(endpoint: .getCategory(id), body: nil)
    }
    
    // MARK: - Notifications
    func getNotifications(page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<AppNotification>, APIError> {
        return request(endpoint: .getNotifications(page: page, size: size), body: nil)
    }
    
    func markNotificationAsRead(id: Int) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .markNotificationAsRead(id), body: nil)
    }
    
    func markAllNotificationsAsRead() -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .markAllNotificationsAsRead, body: nil)
    }
    
    func deleteNotification(id: Int) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .deleteNotification(id), body: nil)
    }
    
    func getUnreadNotificationsCount() -> AnyPublisher<UnreadCountResponse, APIError> {
        return request(endpoint: .getUnreadNotificationsCount, body: nil)
    }
    
    // MARK: - Device Tokens & Push Notifications
    func registerDeviceToken(_ tokenRequest: RegisterDeviceTokenRequest) -> AnyPublisher<DeviceToken, APIError> {
        return request(endpoint: .registerDeviceToken, body: tokenRequest)
    }
    
    func getDeviceTokens() -> AnyPublisher<[DeviceToken], APIError> {
        return request(endpoint: .getDeviceTokens, body: nil)
    }
    
    func updateNotificationPreferences(token: String, preferences: UpdateNotificationPreferencesRequest) -> AnyPublisher<DeviceToken, APIError> {
        return request(endpoint: .updateNotificationPreferences(token), body: preferences)
    }
    
    func testNotification() -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .testNotification, body: nil)
    }
    
    // MARK: - File Upload
    func uploadImage(imageData: Data) -> AnyPublisher<UploadResponse, APIError> {
        return request(endpoint: .uploadImage, body: imageData)
    }
    
    func uploadVideo(videoData: Data) -> AnyPublisher<UploadResponse, APIError> {
        return request(endpoint: .uploadVideo, body: videoData)
    }
    
    func deleteFile(fileId: String) -> AnyPublisher<EmptyResponse, APIError> {
        return request(endpoint: .deleteFile(fileId), body: nil)
    }
}

struct UploadResponse: Codable {
    let fileId: String
    let fileName: String
    let fileUrl: String
    let fileSize: Int64
    let contentType: String
    let uploadedAt: String
}
