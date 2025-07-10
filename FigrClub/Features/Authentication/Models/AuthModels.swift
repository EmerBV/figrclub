//
//  AuthModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

// MARK: - Auth Token
struct AuthToken: Codable, Equatable {
    let id: Int
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case id, token
    }
}

// MARK: - Request Models
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
    let userType: String
    let legalAcceptances: [LegalAcceptance]
    let consents: [Consent]
    
    init(firstName: String, lastName: String, email: String, password: String, username: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.username = username
        self.userType = "REGULAR"
        self.legalAcceptances = [
            LegalAcceptance(documentType: "TERMS_OF_SERVICE", acceptedAt: Date())
        ]
        self.consents = [
            Consent(consentType: "MARKETING_EMAILS", isGranted: false)
        ]
    }
}

struct LegalAcceptance: Codable {
    let documentType: String
    let acceptedAt: Date
}

struct Consent: Codable {
    let consentType: String
    let isGranted: Bool
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let message: String
    let data: AuthData
    let timestamp: Date
    let currency: String?
    let locale: String?
    let status: Int?
}

struct AuthData: Codable {
    let authToken: AuthToken
    let userId: Int
    let email: String
}

struct RegisterResponse: Codable {
    let message: String
    let data: RegisterData
    let timestamp: Date
}

struct RegisterData: Codable {
    let userId: Int
    let email: String
    let fullName: String
    let emailVerified: Bool
    let emailSent: Bool
}

// MARK: - User Response Models - ✅ ACTUALIZADO para reflejar la estructura real de la API
struct UserResponse: Codable {
    let message: String
    let data: UserResponseData
    let timestamp: Date
    let currency: String?
    let locale: String?
    let status: Int?
}

struct UserResponseData: Codable {
    let roleInfo: RoleInfo
    let user: User
}

struct RoleInfo: Codable {
    let isAdmin: Bool
    let roleModifiable: Bool
    let roleModificationReason: String
    let roleName: String
}

// MARK: - Updated User Model - ✅ ACTUALIZADO para coincidir exactamente con la API
struct User: Codable, Identifiable, Equatable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let displayName: String
    let fullName: String
    let birthDate: String?
    let city: String?
    let country: String?
    let phone: String?
    let preferredLanguage: String?
    let active: Bool
    let enabled: Bool
    let accountNonExpired: Bool
    let accountNonLocked: Bool
    let credentialsNonExpired: Bool
    let emailVerified: Bool
    let emailVerifiedAt: String?
    let isVerified: Bool
    let isPrivate: Bool
    let isPro: Bool
    let canAccessProFeatures: Bool
    let proSeller: Bool
    let isActiveSellerProfile: Bool
    let isSellingActive: Bool
    let individualUser: Bool
    let admin: Bool
    let role: String
    let roleDescription: String?
    let roleId: Int
    let hasProfileImage: Bool
    let hasCoverImage: Bool
    let activeImageCount: Int
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let purchasesCount: Int
    let createdAt: String
    let createdBy: String?
    let lastActivityAt: String?
    let imageCapabilities: ImageCapabilities?
    let maxProfileImageSizeMB: String?
    let maxCoverImageSizeMB: String?
    
    // MARK: - Computed Properties
    var username: String {
        return displayName // Usar displayName como username ya que la API no incluye username
    }
    
    var computedFullName: String {
        return "\(firstName) \(lastName)"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Image Capabilities
struct ImageCapabilities: Codable {
    let canUploadProfileImage: Bool
    let canUploadCoverImage: Bool
    let maxProfileImageSize: Int
    let maxProfileImageSizeMB: String
    let maxCoverImageSize: Int
    let maxCoverImageSizeMB: String
}

// MARK: - API Generic Response
struct ApiResponse<T: Codable>: Codable {
    let message: String
    let data: T
    let timestamp: Date?
}

// MARK: - Empty Response
struct EmptyResponse: Codable {}

// MARK: - Error Response
struct APIError: Codable {
    let message: String
    let code: String?
    let details: [String]?
}
