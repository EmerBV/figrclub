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

// MARK: - Error Response
struct APIErrorResponse: Codable {
    let message: String
    let code: String?
    let timestamp: String
    let status: Int?
}
