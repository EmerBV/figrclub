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
    
    // Custom init para debugging
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
#if DEBUG
        print("🔍 Decoding User model...")
        print("Available keys: \(container.allKeys)")
#endif
        
        do {
            id = try container.decode(Int.self, forKey: .id)
            firstName = try container.decode(String.self, forKey: .firstName)
            lastName = try container.decode(String.self, forKey: .lastName)
            email = try container.decode(String.self, forKey: .email)
            username = try container.decode(String.self, forKey: .username)
            userType = try container.decode(UserType.self, forKey: .userType)
            subscriptionType = try container.decode(SubscriptionType.self, forKey: .subscriptionType)
            isVerified = try container.decode(Bool.self, forKey: .isVerified)
            profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
            bio = try container.decodeIfPresent(String.self, forKey: .bio)
            createdAt = try container.decode(String.self, forKey: .createdAt)
            
#if DEBUG
            print("✅ User decoded successfully: \(email)")
#endif
        } catch {
#if DEBUG
            print("❌ Failed to decode User: \(error)")
            if let decodingError = error as? DecodingError {
                DebugHelper.printDecodingError(decodingError)
            }
#endif
            throw error
        }
    }
    
    // Encoding normal
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(userType, forKey: .userType)
        try container.encode(subscriptionType, forKey: .subscriptionType)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    // CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, email, username, userType, subscriptionType, isVerified, profileImageUrl, bio, createdAt
    }
}

// Extensión para crear usuario con inicializador normal también
extension User {
    init(
        id: Int,
        firstName: String,
        lastName: String,
        email: String,
        username: String,
        userType: UserType,
        subscriptionType: SubscriptionType,
        isVerified: Bool,
        profileImageUrl: String?,
        bio: String?,
        createdAt: String
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
        self.userType = userType
        self.subscriptionType = subscriptionType
        self.isVerified = isVerified
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self.createdAt = createdAt
    }
}

enum UserType: String, Codable, CaseIterable {
    case regular = "REGULAR"
    case premium = "PREMIUM"
    case seller = "SELLER"
    case admin = "ADMIN"
}

struct UserStats: Codable {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let likesReceived: Int
    
    // Inicializador por defecto
    init(
        postsCount: Int = 0,
        followersCount: Int = 0,
        followingCount: Int = 0,
        likesReceived: Int = 0
    ) {
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.likesReceived = likesReceived
    }
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

// MARK: - Register Response Model
struct RegisterResponse: Codable {
    let userId: Int
    let email: String
    let fullName: String
    let emailVerified: Bool
    let emailSent: Bool
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
