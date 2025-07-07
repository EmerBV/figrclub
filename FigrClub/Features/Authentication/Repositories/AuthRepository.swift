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

final class AuthRepository: AuthRepositoryProtocol, Sendable {
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
        await tokenManager.saveToken(response.data.authToken.token)
        
        // Get and save user data
        let userResponse = try await authService.getCurrentUser()
        try saveUser(userResponse.data)
        
        return userResponse.data
    }
    
    func register(email: String, password: String, username: String, fullName: String?) async throws -> User {
        // Split fullName into firstName and lastName
        let nameParts = fullName?.components(separatedBy: " ") ?? ["", ""]
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        let request = RegisterRequest(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            username: username
        )
        
        let registerResponse = try await authService.register(request)
        
        // After successful registration, login to get tokens and full user data
        return try await login(email: email, password: password)
    }
    
    func logout() async throws {
        try await authService.logout()
        
        // Clear local data
        await tokenManager.clearTokens()
        try clearUser()
    }
    
    func refreshToken() async throws -> User {
        let response = try await authService.refreshToken()
        
        // Save new token
        await tokenManager.saveToken(response.data.authToken.token)
        
        // Get updated user data
        let userResponse = try await authService.getCurrentUser()
        try saveUser(userResponse.data)
        
        return userResponse.data
    }
    
    func getCurrentUser() async throws -> User {
        // Try to get from cache first
        if let cachedUser = getCachedUser() {
            return cachedUser
        }
        
        // Fetch from server
        let response = try await authService.getCurrentUser()
        try saveUser(response.data)
        
        return response.data
    }
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: User) throws {
        try secureStorage.save(user, forKey: AppConfig.Auth.userKey)
    }
    
    private func getCachedUser() -> User? {
        return try? secureStorage.get(User.self, forKey: AppConfig.Auth.userKey)
    }
    
    private func clearUser() throws {
        try secureStorage.remove(forKey: AppConfig.Auth.userKey)
    }
}
