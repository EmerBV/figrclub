//
//  ApiResponseDTO.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - Base API Response
struct ApiResponseDTO<T: Codable>: BaseDTO {
    let message: String
    let data: T
    let timestamp: Double
    let currency: String?
    let locale: String?
    let status: Int?
}

// MARK: - Empty Response for operations without data
struct EmptyDataDTO: BaseDTO {
    let success: Bool?
    
    init() {
        self.success = true
    }
}

// ✅ Para operaciones como logout, delete, etc.
typealias EmptyResponseDTO = ApiResponseDTO<EmptyDataDTO>

// MARK: - Error Response (Generic)
struct ErrorDetailsDTO: BaseDTO {
    let message: String
    let code: String?
    let details: [String]?
    let path: String?
    let status: Int?
}

typealias ErrorResponseDTO = ApiResponseDTO<ErrorDetailsDTO>
