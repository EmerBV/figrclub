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
    
    // MARK: - Users
    func getUser(id: Int) -> AnyPublisher<User, APIError> {
        return request(endpoint: .getUserById(id), body: nil)
    }
    
    func updateUser(id: Int, updateData: Codable) -> AnyPublisher<User, APIError> {
        return request(endpoint: .updateUser(id), body: updateData)
    }
    
    // MARK: - Posts
    func getPublicFeed(page: Int = 0, size: Int = 20) -> AnyPublisher<PaginatedResponse<Post>, APIError> {
        return request(endpoint: .publicFeed(page: page, size: size), body: nil)
    }
    
    func createPost(_ post: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        return request(endpoint: .createPost, body: post)
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
    
    // MARK: - Device Tokens
    func registerDeviceToken(_ tokenRequest: RegisterDeviceTokenRequest) -> AnyPublisher<DeviceToken, APIError> {
        return request(endpoint: .registerDeviceToken, body: tokenRequest)
    }
    
    func getDeviceTokens() -> AnyPublisher<[DeviceToken], APIError> {
        return request(endpoint: .getDeviceTokens, body: nil)
    }
    
    func updateNotificationPreferences(token: String, preferences: UpdateNotificationPreferencesRequest) -> AnyPublisher<DeviceToken, APIError> {
        return request(endpoint: .updateNotificationPreferences(token), body: preferences)
    }
    
    // MARK: - Categories
    func getCategories() -> AnyPublisher<[Category], APIError> {
        return request(endpoint: .getCategories, body: nil)
    }
}
