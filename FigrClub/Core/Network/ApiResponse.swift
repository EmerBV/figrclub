//
//  ApiResponse.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - API Generic Response
struct ApiResponse<T> {
    let message: String
    let data: T
    let timestamp: Date
    let currency: String?
    let locale: String?
    let status: Int?
}

// MARK: - Empty Response
struct EmptyResponse: Codable {}

// MARK: - Error Response
struct APIError {
    let message: String
    let code: String?
    let details: [String]?
}
