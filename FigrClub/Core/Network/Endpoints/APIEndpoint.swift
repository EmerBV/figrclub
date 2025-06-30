//
//  APIEndpoint.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

// MARK: - API Endpoints
enum APIEndpoint {
    // Authentication
    case register
    case login
    case refreshToken
    case logout
    
    // Users
    case getUserById(Int)
    case updateUser(Int)
    case getUserStats(_ userId: Int)
    case getUserPosts(_ userId: Int, page: Int = 0, size: Int = 20)
    case followUser(_ userId: Int)
    case unfollowUser(_ userId: Int)
    
    // Posts
    case createPost
    case publicFeed(page: Int, size: Int)
    case getPost(Int)
    case updatePost(Int)
    case deletePost(Int)
    case likePost(_ postId: Int)
    case unlikePost(_ postId: Int)
    
    // Comments
    case getComments(postId: Int, page: Int, size: Int)
    case createComment
    
    // Marketplace
    case marketplaceItems(page: Int, size: Int)
    case createMarketplaceItem
    case getMarketplaceItem(Int)
    case updateMarketplaceItem(Int)
    case deleteMarketplaceItem(Int)
    case addToFavorites(Int)
    case removeFromFavorites(Int)
    case getUserFavorites(page: Int, size: Int)
    
    // Categories
    case getCategories
    case getCategory(Int)
    
    // Device Tokens & Notifications
    case registerDeviceToken
    case getDeviceTokens
    case updateNotificationPreferences(String)
    case unregisterDeviceToken(String)
    case testNotification
    case getNotifications(page: Int, size: Int)
    case markNotificationAsRead(_ id: Int)
    case markAllNotificationsAsRead
    case deleteNotification(_ id: Int)
    
    // Chat & Messages
    case getConversations(page: Int, size: Int)
    case getConversation(Int)
    case createConversation
    case getMessages(conversationId: Int, page: Int, size: Int)
    case sendMessage(conversationId: Int)
    case markMessageAsRead(Int)
    
    // Upload & Media
    case uploadImage
    case uploadVideo
    case getImage(String)
    
    // Reports & Moderation
    case createReport
    case getReports(page: Int, size: Int)
    case updateReportStatus(Int)
    
    // Settings & Preferences
    case getUserSettings
    case updateUserSettings
    case updatePrivacySettings
    case deleteAccount
    
    var path: String {
        switch self {
            // Authentication
        case .register:
            return "/auth/register"
        case .login:
            return "/auth/login"
        case .refreshToken:
            return "/auth/refresh"
        case .logout:
            return "/auth/logout"
            
            // Users
        case .getUserById(let id):
            return "/users/\(id)"
        case .updateUser(let id):
            return "/users/\(id)"
        case .getUserStats(let id):
            return "/users/\(id)/stats"
        case .getUserPosts(let id, _, _):
            return "/users/\(id)/posts"
        case .followUser(let id):
            return "/users/\(id)/follow"
        case .unfollowUser(let id):
            return "/users/\(id)/follow"
            
            // Posts
        case .createPost:
            return "/posts"
        case .publicFeed:
            return "/posts/feed/public"
        case .getPost(let id):
            return "/posts/\(id)"
        case .updatePost(let id):
            return "/posts/\(id)"
        case .deletePost(let id):
            return "/posts/\(id)"
        case .likePost(let id):
            return "/posts/\(id)/like"
        case .unlikePost(let id):
            return "/posts/\(id)/like"
            
            // Comments
        case .getComments(let postId, _, _):
            return "/posts/\(postId)/comments"
        case .createComment:
            return "/comments"
            
            // Marketplace
        case .marketplaceItems:
            return "/marketplace/items"
        case .createMarketplaceItem:
            return "/marketplace/items"
        case .getMarketplaceItem(let id):
            return "/marketplace/items/\(id)"
        case .updateMarketplaceItem(let id):
            return "/marketplace/items/\(id)"
        case .deleteMarketplaceItem(let id):
            return "/marketplace/items/\(id)"
        case .addToFavorites(let id):
            return "/marketplace/items/\(id)/favorite"
        case .removeFromFavorites(let id):
            return "/marketplace/items/\(id)/favorite"
        case .getUserFavorites:
            return "/marketplace/favorites"
            
            // Categories
        case .getCategories:
            return "/categories"
        case .getCategory(let id):
            return "/categories/\(id)"
            
            // Device Tokens & Notifications
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
        case .getNotifications:
            return "/notifications"
        case .markNotificationAsRead(let id):
            return "/notifications/\(id)/read"
        case .markAllNotificationsAsRead:
            return "/notifications/mark-all-read"
        case .deleteNotification(let id):
            return "/notifications/\(id)"
            
            // Chat & Messages
        case .getConversations:
            return "/conversations"
        case .getConversation(let id):
            return "/conversations/\(id)"
        case .createConversation:
            return "/conversations"
        case .getMessages(let conversationId, _, _):
            return "/conversations/\(conversationId)/messages"
        case .sendMessage(let conversationId):
            return "/conversations/\(conversationId)/messages"
        case .markMessageAsRead(let id):
            return "/messages/\(id)/read"
            
            // Upload & Media
        case .uploadImage:
            return "/images/upload"
        case .uploadVideo:
            return "/videos/upload"
        case .getImage(let imageId):
            return "/images/\(imageId)"
            
            // Reports & Moderation
        case .createReport:
            return "/reports"
        case .getReports:
            return "/reports"
        case .updateReportStatus(let id):
            return "/reports/\(id)/status"
            
            // Settings & Preferences
        case .getUserSettings:
            return "/settings"
        case .updateUserSettings:
            return "/settings"
        case .updatePrivacySettings:
            return "/settings/privacy"
        case .deleteAccount:
            return "/settings/delete-account"
        }
    }
    
    var method: HTTPMethod {
        switch self {
            // POST methods
        case .register, .login, .refreshToken, .logout,
                .createPost, .createComment, .createMarketplaceItem, .createConversation,
                .sendMessage, .registerDeviceToken, .addToFavorites,
                .likePost, .followUser, .testNotification, .uploadImage,
                .uploadVideo, .createReport:
            return .post
            
            // PUT methods
        case .updateUser, .updatePost, .updateMarketplaceItem,
                .updateNotificationPreferences, .markNotificationAsRead,
                .markAllNotificationsAsRead, .markMessageAsRead,
                .updateReportStatus, .updateUserSettings, .updatePrivacySettings:
            return .put
            
            // DELETE methods
        case .deletePost, .deleteMarketplaceItem, .removeFromFavorites,
                .unfollowUser, .unlikePost, .unregisterDeviceToken,
                .deleteNotification, .deleteAccount:
            return .delete
            
            // GET methods (default)
        default:
            return .get
        }
    }
    
    var queryParameters: [String: Any]? {
        switch self {
        case .publicFeed(let page, let size),
                .marketplaceItems(let page, let size),
                .getNotifications(let page, let size),
                .getConversations(let page, let size),
                .getUserFavorites(let page, let size),
                .getReports(let page, let size):
            return ["page": page, "size": size]
            
        case .getUserPosts(_, let page, let size),
                .getMessages(_, let page, let size),
                .getComments(_, let page, let size):
            return ["page": page, "size": size]
            
        default:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        switch self {
        case .register, .login, .refreshToken, .publicFeed, .marketplaceItems,
                .getMarketplaceItem, .getCategories, .getCategory:
            return false
        default:
            return true
        }
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
