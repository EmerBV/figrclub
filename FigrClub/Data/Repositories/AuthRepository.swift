//
//  AuthRepository.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

// MARK: - Authentication Repository Protocol
protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, username: String) async throws -> User
    func logout() async throws
}

final class AuthRepository: AuthRepositoryProtocol {
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func login(email: String, password: String) async throws -> User {
        let response = try await authService.login(email: email, password: password)
        return response.user
    }
    
    func register(email: String, password: String, username: String) async throws -> User {
        let response = try await authService.register(email: email, password: password, username: username)
        return response.user
    }
    
    func logout() async throws {
        try await authService.logout()
    }
}
