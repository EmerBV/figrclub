//
//  AuthEndpoints.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import Foundation

// MARK: - Auth Endpoints
enum AuthEndpoints: APIEndpoint {
    case login(request: LoginRequest)
    case register(request: RegisterRequest)
    case logout
    case refreshToken
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/auth/refresh"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .logout, .refreshToken:
            return .POST
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .login(let request):
            return try? request.toDictionary()
        case .register(let request):
            return try? request.toDictionary()
        case .logout, .refreshToken:
            return nil
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .login, .register:
            return false
        case .logout, .refreshToken:
            return true
        }
    }
}
