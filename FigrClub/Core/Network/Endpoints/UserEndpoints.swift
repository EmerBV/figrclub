//
//  UserEndpoints.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import Foundation

// MARK: - User Endpoints
enum UserEndpoints: APIEndpoint {
    case getCurrentUser(userId: Int)
    case getUser(id: Int)
    case updateUser(id: Int, data: UserUpdateRequestDTO)
    
    var path: String {
        switch self {
        case .getCurrentUser(let userId):
            return "/users/\(userId)"
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
            return try? data.toDictionary()
        }
    }
}
