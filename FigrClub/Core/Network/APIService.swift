//
//  APIService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - API Service Protocol
protocol APIServiceProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
}

// MARK: - API Service Implementation
final class APIService: APIServiceProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        // Implementación temporal - reemplazar con tu implementación real
        throw APIError.notImplemented
    }
}
