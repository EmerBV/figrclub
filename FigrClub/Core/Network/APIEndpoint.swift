//
//  APIEndpoint.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

// MARK: - Enhanced Endpoint Protocol
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any]? { get }
    var queryParameters: [String: Any]? { get }
    var requiresAuth: Bool { get }
    var isRefreshTokenEndpoint: Bool { get }
    var retryPolicy: RetryPolicy { get }
}

extension APIEndpoint {
    var headers: [String: String] { [:] }
    var body: [String: Any]? { nil }
    var queryParameters: [String: Any]? { nil }
    var requiresAuth: Bool { true }
    var isRefreshTokenEndpoint: Bool { false }
    var retryPolicy: RetryPolicy { .default }
}

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

// MARK: - User Endpoints
enum UserEndpoints: APIEndpoint {
    case getCurrentUser
    case getUser(id: Int)
    case updateUser(id: Int, data: [String: Any])
    
    var path: String {
        switch self {
        case .getCurrentUser:
            return "/users/me"
        case .getUser(let id):
            return "/users/\(id)"
        case .updateUser(let id, _):
            return "/users/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getCurrentUser, .getUser:
            return .GET
        case .updateUser:
            return .PUT
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .getCurrentUser, .getUser:
            return nil
        case .updateUser(_, let data):
            return data
        }
    }
}

// MARK: - Post Endpoints
enum PostEndpoints: APIEndpoint {
    case createPost(data: [String: Any])
    case getPosts(page: Int?, limit: Int?)
    case getPost(id: Int)
    case updatePost(id: Int, data: [String: Any])
    case deletePost(id: Int)
    
    var path: String {
        switch self {
        case .createPost, .getPosts:
            return "/posts"
        case .getPost(let id), .updatePost(let id, _), .deletePost(let id):
            return "/posts/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .createPost:
            return .POST
        case .getPosts, .getPost:
            return .GET
        case .updatePost:
            return .PUT
        case .deletePost:
            return .DELETE
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .createPost(let data), .updatePost(_, let data):
            return data
        case .getPosts, .getPost, .deletePost:
            return nil
        }
    }
}

// MARK: - Helper Extension
extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
}


