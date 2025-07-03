//
//  UserModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

// MARK: - User Models
struct User: Codable, Identifiable, Equatable {
    let id: Int
    let firstName: String
    let lastName: String
    let username: String
    let email: String
    let userType: UserType
    let profileImageUrl: String?
    let bio: String?
    let stats: UserStats?
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    let isVerified: Bool
    let isPrivate: Bool
    
    // Computed properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        "@\(username)"
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    // Initializer with default values
    init(
        id: Int,
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        userType: UserType,
        profileImageUrl: String? = nil,
        bio: String? = nil,
        stats: UserStats? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true,
        isVerified: Bool = false,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.userType = userType
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self.stats = stats
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
        self.isVerified = isVerified
        self.isPrivate = isPrivate
    }
}

// MARK: - User Type
enum UserType: String, Codable, CaseIterable {
    case regular = "REGULAR"
    case premium = "PREMIUM"
    case business = "BUSINESS"
    case admin = "ADMIN"
    
    var displayName: String {
        switch self {
        case .regular:
            return "Regular"
        case .premium:
            return "Premium"
        case .business:
            return "Business"
        case .admin:
            return "Administrador"
        }
    }
    
    var icon: String {
        switch self {
        case .regular:
            return "person.circle"
        case .premium:
            return "star.circle"
        case .business:
            return "briefcase.circle"
        case .admin:
            return "shield.circle"
        }
    }
}

// MARK: - User Stats
struct UserStats: Codable, Equatable {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let likesCount: Int
    let commentsCount: Int
    
    init(
        postsCount: Int = 0,
        followersCount: Int = 0,
        followingCount: Int = 0,
        likesCount: Int = 0,
        commentsCount: Int = 0
    ) {
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
    }
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let authToken: AuthToken
    let refreshToken: AuthToken?
    let userId: Int
    let expiresAt: String?
    let email: String?  // Añadido para compatibilidad
    
    var expiryDate: Date? {
        guard let expiresAt = expiresAt else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: expiresAt)
    }
}

/*
 extension User {
 static func mock() -> User {
 return User(
 id: 1,
 firstName: "Juan",
 lastName: "Pérez",
 username: "juanperez",
 email: "juan@example.com",
 userType: .regular,
 profileImageUrl: nil,
 bio: "Coleccionista de figuras de anime",
 stats: <#T##UserStats?#>,
 createdAt: "2024-01-01T00:00:00Z",
 updatedAt: "2024-01-01T00:00:00Z",
 isActive: true,
 isVerified: false,
 isPrivate: false
 )
 }
 }
 */

enum SubscriptionType: String, Codable, CaseIterable {
    case free = "FREE"
    case premium = "PREMIUM"
    case pro = "PRO"
}


