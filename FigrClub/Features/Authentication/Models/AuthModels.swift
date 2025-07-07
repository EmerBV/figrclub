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

struct UserResponse: Codable {
    let message: String
    let data: User
    let timestamp: Date
}

// MARK: - Updated User Model
struct User: Codable, Identifiable, Equatable {
    let id: Int // Cambiado de String a Int según API
    let firstName: String
    let lastName: String
    let email: String
    let username: String
    let userType: String
    let subscriptionType: String
    let isVerified: Bool
    let profileImageUrl: String?
    let bio: String?
    let createdAt: Date
    let updatedAt: Date?
    
    // Computed properties
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var followersCount: Int { 0 } // TODO: Implementar cuando esté en API
    var followingCount: Int { 0 } // TODO: Implementar cuando esté en API
    var postsCount: Int { 0 } // TODO: Implementar cuando esté en API
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
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
