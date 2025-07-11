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
        
        // ✅ Guardar tanto token como userId de la respuesta de login
        await tokenManager.saveAuthData(
            token: response.data.authToken.token,
            userId: response.data.userId  // 🔑 Este viene de la respuesta de login
        )
        
        Logger.info("✅ AuthRepository: Login tokens saved - UserId: \(response.data.userId)")
        
        // ✅ Obtener los datos completos del usuario usando el userId
        let userResponse = try await authService.getCurrentUser(userId: response.data.userId)
        // ✅ CORREGIDO: Ahora acceder al usuario desde la estructura anidada
        try saveUser(userResponse.data.user)
        
        Logger.info("✅ AuthRepository: Login successful for user: \(userResponse.data.user.displayName)")
        return userResponse.data.user
    }
    
    func register(email: String, password: String, username: String, fullName: String?) async throws -> User {
        // Split fullName into firstName and lastName
        let nameParts = fullName?.components(separatedBy: " ") ?? ["", ""]
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        // ✅ Create domain model request
        let request = RegisterRequest(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            username: username,
            userType: "REGULAR",
            legalAcceptances: [
                LegalAcceptance(documentType: "TERMS_OF_SERVICE", acceptedAt: Date())
            ],
            consents: [
                Consent(consentType: "MARKETING_EMAILS", isGranted: false)
            ]
        )
        
        // Service handles DTO conversion internally
        let registerResponse = try await authService.register(request)
        Logger.info("✅ AuthRepository: Registration successful for user: \(registerResponse.data.email)")
        
        // After successful registration, login to get tokens and full user data
        return try await login(email: email, password: password)
    }
    
    func logout() async throws {
        try await authService.logout()
        
        // Clear local data
        await tokenManager.clearTokens()
        try clearUser()
        
        Logger.info("✅ AuthRepository: Logout successful - Local data cleared")
    }
    
    func refreshToken() async throws -> User {
        let response = try await authService.refreshToken()
        
        // Save new token (userId should remain the same)
        await tokenManager.saveToken(response.data.authToken.token)
        
        // Get updated user data using stored userId
        guard let userId = await tokenManager.getCurrentUserId() else {
            throw AuthError.noUserIdFound
        }
        
        let userResponse = try await authService.getCurrentUser(userId: userId)
        // ✅ CORREGIDO: Ahora acceder al usuario desde la estructura anidada
        try saveUser(userResponse.data.user)
        
        Logger.info("✅ AuthRepository: Token refresh successful")
        return userResponse.data.user
    }
    
    func getCurrentUser() async throws -> User {
        // Try to get from cache first
        if let cachedUser = getCachedUser() {
            Logger.debug("🔄 AuthRepository: Using cached user data")
            return cachedUser
        }
        
        // ✅ Obtener userId del TokenManager
        guard let userId = await tokenManager.getCurrentUserId() else {
            Logger.error("❌ AuthRepository: No userId found for getCurrentUser")
            throw AuthError.noUserIdFound
        }
        
        // Fetch from server using userId
        let response = try await authService.getCurrentUser(userId: userId)
        // ✅ CORREGIDO: Ahora acceder al usuario desde la estructura anidada
        try saveUser(response.data.user)
        
        Logger.info("✅ AuthRepository: Current user fetched from server")
        return response.data.user
    }
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: User) throws {
        try secureStorage.save(user, forKey: AppConfig.Auth.userKey)
        Logger.debug("💾 AuthRepository: User data saved to secure storage")
    }
    
    private func getCachedUser() -> User? {
        return try? secureStorage.get(User.self, forKey: AppConfig.Auth.userKey)
    }
    
    private func clearUser() throws {
        try secureStorage.remove(forKey: AppConfig.Auth.userKey)
        Logger.debug("🗑️ AuthRepository: User data cleared from secure storage")
    }
}
