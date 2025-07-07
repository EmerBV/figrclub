//
//  AuthModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct User: Codable {
    let id: String
    let email: String
    let username: String
}

enum APIError: Error {
    case notImplemented
    case networkError
    case authenticationFailed
}

// APIEndpoint temporal - reemplazar con tu implementación
enum APIEndpoint {
    case login
    case register
}


