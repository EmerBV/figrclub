//
//  APIEndpoint.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

enum APIEndpoint {
    // Auth endpoints
    case login
    case register
    case logout
    case refreshToken
    case profile
    
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
        case .profile:
            return "/auth/profile"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .logout, .refreshToken:
            return .POST
        case .profile:
            return .GET
        }
    }
    
    var requiresAuthentication: Bool {
        switch self {
        case .login, .register:
            return false
        case .logout, .refreshToken, .profile:
            return true
        }
    }
    
    func url(baseURL: String = AppConfig.API.baseURL) -> URL? {
        return URL(string: baseURL + path)
    }
}


