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
    let isPrivate: Bool
    let profileImageUrl: String?
    let bio: String?
    let createdAt: String
    let updatedAt: String?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        return username.isEmpty ? fullName : "@\(username)"
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return firstInitial + lastInitial
    }
    
    var formattedUsername: String {
        return username.hasPrefix("@") ? username : "@\(username)"
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
            isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
            profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
            bio = try container.decodeIfPresent(String.self, forKey: .bio)
            createdAt = try container.decode(String.self, forKey: .createdAt)
            updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            
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
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, email, username, userType, subscriptionType, isVerified, isPrivate, profileImageUrl, bio, createdAt, updatedAt
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
        isPrivate: Bool,
        profileImageUrl: String?,
        bio: String?,
        createdAt: String,
        updatedAt: String?
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
        self.userType = userType
        self.subscriptionType = subscriptionType
        self.isVerified = isVerified
        self.isPrivate = isPrivate
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension User {
    static func mock() -> User {
        return User(
            id: 1,
            firstName: "Juan",
            lastName: "Pérez",
            email: "juan@example.com",
            username: "juanperez",
            userType: .regular,
            subscriptionType: .free,
            isVerified: false,
            isPrivate: false,
            profileImageUrl: nil,
            bio: "Coleccionista de figuras de anime",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: nil
        )
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
    let likesReceivedCount: Int
    let marketplaceItemsCount: Int
    let totalViews: Int
    
    var formattedFollowersCount: String {
        return formatCount(followersCount)
    }
    
    var formattedFollowingCount: String {
        return formatCount(followingCount)
    }
    
    var formattedPostsCount: String {
        return formatCount(postsCount)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    // Inicializador por defecto
    init(
        postsCount: Int = 0,
        followersCount: Int = 0,
        followingCount: Int = 0,
        likesReceivedCount: Int = 0,
        marketplaceItemsCount: Int = 0,
        totalViews: Int = 0
    ) {
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.likesReceivedCount = likesReceivedCount
        self.marketplaceItemsCount = marketplaceItemsCount
        self.totalViews = totalViews
    }
}

enum SubscriptionType: String, Codable, CaseIterable {
    case free = "FREE"
    case premium = "PREMIUM"
    case pro = "PRO"
}

struct LegalAcceptance: Codable {
    let documentType: String
    let acceptedAt: String
}

struct Consent: Codable {
    let consentType: String
    let isGranted: Bool
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


