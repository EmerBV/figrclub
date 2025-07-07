//
//  AuthRepository.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol AuthRepositoryProtocol: Sendable {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, username: String, fullName: String?) async throws -> User
    func logout() async throws
    func refreshToken() async throws -> User
    func getCurrentUser() async throws -> User
}

final class AuthRepository: AuthRepositoryProtocol {
    private let authService: AuthServiceProtocol
    private let tokenManager: TokenManager
    private let secureStorage: SecureStorageProtocol
    
    init(authService: AuthServiceProtocol, tokenManager: TokenManager, secureStorage: SecureStorageProtocol) {
        self.authService = authService
        self.tokenManager = tokenManager
        self.secureStorage = secureStorage
    }
    
    func login(email: String, password: String) async throws -> User {
        let request = LoginRequest(email: email, password: password)
        let response = try await authService.login(request)
        
        // Save tokens
        await tokenManager.saveToken(response.token)
        if let refreshToken = response.refreshToken {
            await tokenManager.saveRefreshToken(refreshToken)
        }
        
        // Save user data
        try saveUser(response.user)
        
        return response.user
    }
    
    func register(email: String, password: String, username: String, fullName: String?) async throws -> User {
        let request = RegisterRequest(email: email, password: password, username: username, fullName: fullName)
        let response = try await authService.register(request)
        
        // Save tokens
        await tokenManager.saveToken(response.token)
        if let refreshToken = response.refreshToken {
            await tokenManager.saveRefreshToken(refreshToken)
        }
        
        // Save user data
        try saveUser(response.user)
        
        return response.user
    }
    
    func logout() async throws {
        // Call logout endpoint
        try await authService.logout()
        
        // Clear tokens and user data
        await tokenManager.clearTokens()
        try clearUser()
    }
    
    func refreshToken() async throws -> User {
        let response = try await authService.refreshToken()
        
        // Update tokens
        await tokenManager.saveToken(response.token)
        if let refreshToken = response.refreshToken {
            await tokenManager.saveRefreshToken(refreshToken)
        }
        
        // Update user data
        try saveUser(response.user)
        
        return response.user
    }
    
    func getCurrentUser() async throws -> User {
        return try await authService.getCurrentUser()
    }
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: User) throws {
        try secureStorage.save(user, key: AppConfig.Auth.userKey)
    }
    
    private func loadUser() throws -> User? {
        return try secureStorage.load(User.self, key: AppConfig.Auth.userKey)
    }
    
    private func clearUser() throws {
        try secureStorage.delete(key: AppConfig.Auth.userKey)
    }
}
