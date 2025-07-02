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

struct AuthResponse: Codable {
    let authToken: AuthToken
    let userId: Int
    let email: String
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

// MARK: - Paginated Response
struct PaginatedResponse<T: Codable>: Codable {
    let size: Int
    let page: Int
    let totalPages: Int
    let totalElements: Int
    let first: Bool
    let last: Bool
    let content: [T]
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
#if DEBUG
        print("🔍 Decoding PaginatedResponse<\(T.self)>...")
        print("Available keys: \(container.allKeys.map { $0.stringValue })")
#endif
        
        do {
            size = try container.decode(Int.self, forKey: .size)
            page = try container.decode(Int.self, forKey: .page)
            totalPages = try container.decode(Int.self, forKey: .totalPages)
            totalElements = try container.decode(Int.self, forKey: .totalElements)
            
            // Decode booleans with fallback
            first = try container.decodeBool(forKey: .first)
            last = try container.decodeBool(forKey: .last)
            
            content = try container.decode([T].self, forKey: .content)
            
#if DEBUG
            print("✅ PaginatedResponse decoded successfully: \(content.count) items")
#endif
        } catch {
#if DEBUG
            print("❌ Failed to decode PaginatedResponse: \(error)")
            if let decodingError = error as? DecodingError {
                DebugHelper.printDecodingError(decodingError)
            }
#endif
            throw error
        }
    }
    
    // MARK: - Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(size, forKey: .size)
        try container.encode(page, forKey: .page)
        try container.encode(totalPages, forKey: .totalPages)
        try container.encode(totalElements, forKey: .totalElements)
        try container.encode(first, forKey: .first)
        try container.encode(last, forKey: .last)
        try container.encode(content, forKey: .content)
    }
    
    enum CodingKeys: String, CodingKey {
        case size, page, totalPages, totalElements, first, last, content
    }
}

// MARK: - Support Models
struct EmptyResponse: Codable {}

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
        return hasNextPage ? page + 1 : nil
    }
    
    var previousPage: Int? {
        return hasPreviousPage ? page - 1 : nil
    }
}
