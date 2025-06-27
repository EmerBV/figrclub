//
//  APIResponse.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let message: String
    let data: T?
    let timestamp: String
}

struct APIError: Error, Codable {
    let message: String
    let code: String?
    let timestamp: String
    
    var localizedDescription: String {
        return message
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Endpoints
enum APIEndpoint {
    // Authentication
    case register
    case login
    case refreshToken
    
    // Users
    case getUserById(Int)
    case updateUser(Int)
    
    // Posts
    case createPost
    case publicFeed(page: Int, size: Int)
    
    // Marketplace
    case marketplaceItems(page: Int, size: Int)
    case createMarketplaceItem
    case getMarketplaceItem(Int)
    case addToFavorites(Int)
    case removeFromFavorites(Int)
    
    // Device Tokens
    case registerDeviceToken
    case getDeviceTokens
    case updateNotificationPreferences(String)
    case unregisterDeviceToken(String)
    case testNotification
    
    // Categories
    case getCategories
    
    var path: String {
        switch self {
        case .register:
            return "/auth/register"
        case .login:
            return "/auth/login"
        case .refreshToken:
            return "/auth/refresh"
        case .getUserById(let id):
            return "/users/\(id)"
        case .updateUser(let id):
            return "/users/\(id)"
        case .createPost:
            return "/posts"
        case .publicFeed:
            return "/posts/feed/public"
        case .marketplaceItems:
            return "/marketplace/items"
        case .createMarketplaceItem:
            return "/marketplace/items"
        case .getMarketplaceItem(let id):
            return "/marketplace/items/\(id)"
        case .addToFavorites(let id):
            return "/marketplace/items/\(id)/favorite"
        case .removeFromFavorites(let id):
            return "/marketplace/items/\(id)/favorite"
        case .registerDeviceToken:
            return "/device-tokens/register"
        case .getDeviceTokens:
            return "/device-tokens"
        case .updateNotificationPreferences(let token):
            return "/device-tokens/\(token)/preferences"
        case .unregisterDeviceToken(let token):
            return "/device-tokens/\(token)"
        case .testNotification:
            return "/device-tokens/test"
        case .getCategories:
            return "/categories"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .register, .login, .refreshToken, .createPost, .createMarketplaceItem,
             .registerDeviceToken, .addToFavorites, .testNotification:
            return .post
        case .updateUser, .updateNotificationPreferences:
            return .put
        case .removeFromFavorites, .unregisterDeviceToken:
            return .delete
        case .getUserById, .publicFeed, .marketplaceItems, .getMarketplaceItem,
             .getDeviceTokens, .getCategories:
            return .get
        }
    }
    
    var queryParameters: [String: Any]? {
        switch self {
        case .publicFeed(let page, let size):
            return ["page": page, "size": size]
        case .marketplaceItems(let page, let size):
            return ["page": page, "size": size]
        default:
            return nil
        }
    }
}
