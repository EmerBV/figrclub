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
    let timestamp: String
}
