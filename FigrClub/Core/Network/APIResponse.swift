//
//  APIResponse.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let message: String
    let data: T?
    let locale: String?
    let currency: String?
    let status: Int?
    let timestamp: Int64
}

// MARK: - Register Response Model
struct RegisterResponse: Codable {
    let userId: Int
    let email: String
    let fullName: String
    let emailVerified: Bool
    let emailSent: Bool
}

// MARK: - Wrapper para respuestas que pueden venir wrapeadas o no
struct FlexibleAPIResponse<T: Codable>: Codable {
    let content: T
    
    init(from decoder: Decoder) throws {
        // Intentar decodificar como APIResponse wrapeada primero
        if let apiResponse = try? APIResponse<T>(from: decoder) {
            guard let data = apiResponse.data else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "API response data is null"
                    )
                )
            }
            self.content = data
        } else {
            // Si falla, intentar decodificar directamente
            self.content = try T(from: decoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try content.encode(to: encoder)
    }
}

struct UnreadCountResponse: Codable {
    let count: Int
}

// MARK: - Convenience Extensions
extension PaginatedResponse {
    var isEmpty: Bool {
        return content.isEmpty
    }
    
    var hasNextPage: Bool {
        return !last
    }
    
    var hasPreviousPage: Bool {
        return !first
    }
    
    var nextPage: Int? {
        return hasNextPage ? currentPage + 1 : nil
    }
    
    var previousPage: Int? {
        return hasPreviousPage ? currentPage - 1 : nil
    }
}
