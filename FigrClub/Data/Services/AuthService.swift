//
//  AuthService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(email: String, password: String, username: String) async throws -> AuthResponse
    func logout() async throws
}

final class AuthService: AuthServiceProtocol {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        // Implementación temporal
        throw APIError.notImplemented
    }
    
    func register(email: String, password: String, username: String) async throws -> AuthResponse {
        // Implementación temporal
        throw APIError.notImplemented
    }
    
    func logout() async throws {
        // Implementación temporal
    }
}
