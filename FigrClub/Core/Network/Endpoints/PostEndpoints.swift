//
//  PostEndpoints.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import Foundation

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
