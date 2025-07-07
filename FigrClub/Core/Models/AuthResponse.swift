//
//  AuthResponse.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

struct AuthResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String?
    let expiresAt: Date?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
    let fullName: String?
}
