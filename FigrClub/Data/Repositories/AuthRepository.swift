//
//  AuthRepository.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

// MARK: - Authentication Repository Protocol
protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
}

final class AuthRepository: AuthRepositoryProtocol {
    
    private let authService: AuthServiceProtocol
    
    init(
        authService: AuthServiceProtocol
    ) {
        self.authService = authService
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        return
    }
    
    
}
