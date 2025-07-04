//
//  AuthModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

struct AuthToken: Codable, Equatable {
    let id: Int
    let token: String
}

struct AuthResponse: Codable {
    let authToken: AuthToken
    let userId: Int
    let email: String?
}

struct TokenInfo {
    let accessToken: String
    let refreshToken: String?
    let userId: Int
    let expiryDate: Date?
    let isValid: Bool
    let isExpired: Bool
    
    var timeUntilExpiry: TimeInterval? {
        guard let expiryDate = expiryDate else { return nil }
        return expiryDate.timeIntervalSinceNow
    }
    
    var formattedExpiryDate: String? {
        guard let expiryDate = expiryDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expiryDate)
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}


