//
//  UserModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

// MARK: - User Models
struct User: Codable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let username: String
    let userType: UserType
    let subscriptionType: SubscriptionType
    let isVerified: Bool
    let profileImageUrl: String?
    let bio: String?
    let createdAt: String
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

enum UserType: String, Codable, CaseIterable {
    case regular = "REGULAR"
    case premium = "PREMIUM"
    case seller = "SELLER"
    case admin = "ADMIN"
}

struct UserStats {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let likesReceived: Int
}

struct UpdateUserRequest: Codable {
    let firstName: String
    let lastName: String
    let username: String
    let bio: String?
}

enum SubscriptionType: String, Codable, CaseIterable {
    case free = "FREE"
    case premium = "PREMIUM"
    case pro = "PRO"
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let username: String
    let userType: UserType
    let legalAcceptances: [LegalAcceptance]
    let consents: [Consent]
}

struct AuthResponse: Codable {
    let authToken: AuthToken
    let userId: Int
    let email: String
}

struct AuthToken: Codable {
    let id: Int
    let token: String
}

struct LegalAcceptance: Codable {
    let documentType: String
    let acceptedAt: String
}

struct Consent: Codable {
    let consentType: String
    let isGranted: Bool
}

// MARK: - Post Models
struct Post: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String?
    let authorId: Int
    let author: User?
    let categoryId: Int?
    let category: Category?
    let visibility: PostVisibility
    let status: PostStatus
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let createdAt: String
    let updatedAt: String?
    let images: [String]?
    let hashtags: [String]?
    let location: String?
    let isFeatured: Bool
    
    // User interaction flags
    let isLikedByCurrentUser: Bool?
    let isBookmarkedByCurrentUser: Bool?
}

enum PostVisibility: String, Codable, CaseIterable {
    case `public` = "PUBLIC"
    case followers = "FOLLOWERS"
    case `private` = "PRIVATE"
}

enum PostStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case published = "PUBLISHED"
    case archived = "ARCHIVED"
    case deleted = "DELETED"
}

struct CreatePostRequest: Codable {
    let title: String
    let content: String
    let categoryId: Int?
    let visibility: PostVisibility
    let publishNow: Bool
    let location: String?
    let hashtags: [String]?
}

// MARK: - Marketplace Models
struct MarketplaceItem: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let currency: String
    let condition: ItemCondition
    let category: Category
    let images: [String]
    let seller: User
    let status: ItemStatus
    let createdAt: String
    let updatedAt: String?
    let stockQuantity: Int
    let viewsCount: Int
    let favoritesCount: Int
    let location: ItemLocation?
    
    // User interaction flags
    let isFavoritedByCurrentUser: Bool?
    let canEdit: Bool?
    let canDelete: Bool?
    let canMakeOffer: Bool?
    let canAskQuestion: Bool?
}

enum ItemCondition: String, Codable, CaseIterable {
    case new = "NEW"
    case likeNew = "LIKE_NEW"
    case good = "GOOD"
    case fair = "FAIR"
    case poor = "POOR"
}

enum ItemStatus: String, Codable, CaseIterable {
    case available = "AVAILABLE"
    case sold = "SOLD"
    case reserved = "RESERVED"
    case inactive = "INACTIVE"
}

struct ItemLocation: Codable {
    let country: String
    let city: String
    let region: String?
}

struct CreateMarketplaceItemRequest: Codable {
    let title: String
    let description: String
    let category: String
    let basePrice: Double
    let currency: String
    let condition: ItemCondition
    let baseStockQuantity: Int
    let negotiable: Bool
    let acceptsOffers: Bool
    let allowsQuestions: Bool
    let freeShipping: Bool
    let pickupAvailable: Bool
    let country: String
    let city: String
    let region: String?
}

// MARK: - Category Models
struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let parentId: Int?
    let imageUrl: String?
    let isActive: Bool
}

// MARK: - Device Token Models
struct DeviceToken: Codable, Identifiable {
    let id: Int
    let deviceType: DeviceType
    let deviceName: String?
    let appVersion: String
    let osVersion: String
    let lastUsedAt: String
    let notificationsEnabled: Bool
    let marketingEnabled: Bool
    let salesEnabled: Bool
    let purchaseEnabled: Bool
}

enum DeviceType: String, Codable, CaseIterable {
    case ios = "IOS"
    case android = "ANDROID"
    case web = "WEB"
}

struct RegisterDeviceTokenRequest: Codable {
    let token: String
    let deviceType: DeviceType
    let deviceName: String?
    let appVersion: String
    let osVersion: String
}

struct UpdateNotificationPreferencesRequest: Codable {
    let notificationsEnabled: Bool
    let marketingEnabled: Bool
    let salesEnabled: Bool
    let purchaseEnabled: Bool
}

// MARK: - Pagination Models
struct PaginatedResponse<T: Codable>: Codable {
    let content: [T]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
}

// MARK: - Notification Models
struct AppNotification: Codable, Identifiable {
    let id: Int
    let title: String
    let message: String
    let type: NotificationType
    let entityType: String?
    let entityId: Int?
    let isRead: Bool
    let createdAt: String
}

enum NotificationType: String, Codable, CaseIterable {
    case like = "LIKE"
    case comment = "COMMENT"
    case follow = "FOLLOW"
    case newPost = "NEW_POST"
    case marketplaceSale = "MARKETPLACE_SALE"
    case marketplaceQuestion = "MARKETPLACE_QUESTION"
    case system = "SYSTEM"
}

// MARK: - UserType Extensions
extension UserType {
    var displayName: String {
        switch self {
        case .regular: return "Usuario Regular"
        case .premium: return "Usuario Premium"
        case .seller: return "Vendedor"
        case .admin: return "Administrador"
        }
    }
    
    var description: String {
        switch self {
        case .regular: return "Acceso básico a todas las funciones"
        case .premium: return "Funciones avanzadas y contenido exclusivo"
        case .seller: return "Vende productos en el marketplace"
        case .admin: return "Administración completa del sistema"
        }
    }
}
