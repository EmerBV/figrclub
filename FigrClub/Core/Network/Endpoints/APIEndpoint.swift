//
//  APIEndpoint.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - HTTPMethod Extension
extension HTTPMethod {
    static let get = HTTPMethod.GET
    static let post = HTTPMethod.POST
    static let put = HTTPMethod.PUT
    static let delete = HTTPMethod.DELETE
    static let patch = HTTPMethod.PATCH
}

