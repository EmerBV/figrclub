//
//  TokenManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import KeychainAccess
import Combine

final class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    private let keychain: Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let userIdKey = "user_id"
    private let tokenExpiryKey = "token_expiry"
    
    @Published var isAuthenticated = false
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<String?, Never>?
    
    private init() {
        // Configurar keychain con service específico para la app
        self.keychain = Keychain(service: "com.emerbv.FigrClub")
            .accessibility(.whenUnlockedThisDeviceOnly)
            .synchronizable(false)
        
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    func saveTokens(accessToken: String, refreshToken: String? = nil, userId: Int, expiresIn: TimeInterval? = nil) {
        do {
            try keychain.set(accessToken, key: accessTokenKey)
            
            if let refreshToken = refreshToken {
                try keychain.set(refreshToken, key: refreshTokenKey)
            }
            
            try keychain.set(String(userId), key: userIdKey)
            
            // Save expiry time
            if let expiresIn = expiresIn {
                let expiryDate = Date().addingTimeInterval(expiresIn)
                try keychain.set(ISO8601DateFormatter().string(from: expiryDate), key: tokenExpiryKey)
            }
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
            
            Logger.shared.info("Tokens saved successfully for user: \(userId)", category: "auth")
            
        } catch {
            Logger.shared.error("Failed to save tokens", error: error, category: "auth")
        }
    }
    
    func getAccessToken() -> String? {
        do {
            return try keychain.get(accessTokenKey)
        } catch {
            Logger.shared.error("Failed to get access token", error: error, category: "auth")
            return nil
        }
    }
    
    func getRefreshToken() -> String? {
        do {
            return try keychain.get(refreshTokenKey)
        } catch {
            Logger.shared.error("Failed to get refresh token", error: error, category: "auth")
            return nil
        }
    }
    
    func getUserId() -> Int? {
        do {
            guard let userIdString = try keychain.get(userIdKey) else { return nil }
            return Int(userIdString)
        } catch {
            Logger.shared.error("Failed to get user ID", error: error, category: "auth")
            return nil
        }
    }
    
    func getTokenExpiry() -> Date? {
        do {
            guard let expiryString = try keychain.get(tokenExpiryKey) else { return nil }
            return ISO8601DateFormatter().date(from: expiryString)
        } catch {
            Logger.shared.error("Failed to get token expiry", error: error, category: "auth")
            return nil
        }
    }
    
    func clearTokens() {
        do {
            try keychain.remove(accessTokenKey)
            try keychain.remove(refreshTokenKey)
            try keychain.remove(userIdKey)
            try keychain.remove(tokenExpiryKey)
            
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
            
            Logger.shared.info("Tokens cleared successfully", category: "auth")
            
        } catch {
            Logger.shared.error("Failed to clear tokens", error: error, category: "auth")
        }
    }
    
    // MARK: - Token Validation and Refresh
    
    func isTokenValid() -> Bool {
        guard let accessToken = getAccessToken(), !accessToken.isEmpty else {
            return false
        }
        
        // Check if token is expired
        if let expiryDate = getTokenExpiry() {
            return expiryDate > Date().addingTimeInterval(300) // 5 minutes buffer
        }
        
        // If no expiry date, assume valid for now
        return true
    }
    
    func isTokenExpired() -> Bool {
        guard let expiryDate = getTokenExpiry() else {
            return false // No expiry date, assume not expired
        }
        
        return expiryDate <= Date()
    }
    
    func willTokenExpireSoon(within timeInterval: TimeInterval = 300) -> Bool {
        guard let expiryDate = getTokenExpiry() else {
            return false
        }
        
        return expiryDate <= Date().addingTimeInterval(timeInterval)
    }
    
    // MARK: - Token Refresh
    
    func refreshTokenIfNeeded() async -> String? {
        // If there's already a refresh in progress, wait for it
        if let existingTask = refreshTask {
            return await existingTask.value
        }
        
        // Check if refresh is needed
        guard !isTokenValid() else {
            return getAccessToken()
        }
        
        // Create refresh task
        refreshTask = Task {
            await performTokenRefresh()
        }
        
        defer {
            refreshTask = nil
        }
        
        return await refreshTask?.value
    }
    
    private func performTokenRefresh() async -> String? {
        guard let refreshToken = getRefreshToken() else {
            Logger.shared.warning("No refresh token available", category: "auth")
            await clearTokensOnMainActor()
            return nil
        }
        
        do {
            Logger.shared.info("Attempting to refresh token", category: "auth")
            
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            
            let response: AuthResponse = try await APIService.shared
                .request(endpoint: .refreshToken, body: request)
                .async()
            
            // Save new tokens
            saveTokens(
                accessToken: response.authToken.token,
                refreshToken: response.refreshToken?.token,
                userId: response.userId,
                expiresIn: response.authToken.expiresIn
            )
            
            Logger.shared.info("Token refreshed successfully", category: "auth")
            
            return response.authToken.token
            
        } catch {
            Logger.shared.error("Failed to refresh token", error: error, category: "auth")
            
            // If refresh fails, clear all tokens
            await clearTokensOnMainActor()
            
            return nil
        }
    }
    
    @MainActor
    private func clearTokensOnMainActor() {
        clearTokens()
    }
    
    // MARK: - Authentication State
    
    func checkAuthenticationStatus() {
        let hasValidToken = isTokenValid()
        
        DispatchQueue.main.async {
            self.isAuthenticated = hasValidToken
        }
        
        Logger.shared.info("Authentication status checked: \(hasValidToken)", category: "auth")
    }
    
    // MARK: - Authorization Header
    
    func getAuthorizationHeader() -> String? {
        guard let accessToken = getAccessToken() else {
            return nil
        }
        
        return "Bearer \(accessToken)"
    }
    
    func getAuthorizationHeaderAsync() async -> String? {
        // Try to get current token first
        if let token = getAccessToken(), isTokenValid() {
            return "Bearer \(token)"
        }
        
        // If token is invalid, try to refresh
        if let refreshedToken = await refreshTokenIfNeeded() {
            return "Bearer \(refreshedToken)"
        }
        
        return nil
    }
    
    // MARK: - Token Information
    
    func getTokenInfo() -> TokenInfo? {
        guard let accessToken = getAccessToken(),
              let userId = getUserId() else {
            return nil
        }
        
        return TokenInfo(
            accessToken: accessToken,
            refreshToken: getRefreshToken(),
            userId: userId,
            expiryDate: getTokenExpiry(),
            isValid: isTokenValid(),
            isExpired: isTokenExpired()
        )
    }
    
    // MARK: - Debug Information
    
#if DEBUG
    func getDebugInfo() -> [String: Any] {
        return [
            "hasAccessToken": getAccessToken() != nil,
            "hasRefreshToken": getRefreshToken() != nil,
            "userId": getUserId() ?? "nil",
            "expiryDate": getTokenExpiry()?.description ?? "nil",
            "isAuthenticated": isAuthenticated,
            "isTokenValid": isTokenValid(),
            "isTokenExpired": isTokenExpired(),
            "willExpireSoon": willTokenExpireSoon()
        ]
    }
#endif
}

// MARK: - Supporting Models

struct TokenInfo {
    let accessToken: String
    let refreshToken: String?
    let userId: Int
    let expiryDate: Date?
    let isValid: Bool
    let isExpired: Bool
    
    var timeUntilExpiry: TimeInterval? {
        guard let expiryDate = expiryDate else { return nil }
        return expiryDate.timeIntervalSinceNow
    }
    
    var formattedExpiryDate: String? {
        guard let expiryDate = expiryDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expiryDate)
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct AuthToken: Codable {
    let token: String
    let expiresIn: TimeInterval?
    let tokenType: String
    
    init(token: String, expiresIn: TimeInterval? = nil, tokenType: String = "Bearer") {
        self.token = token
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }
}

struct AuthResponse: Codable {
    let authToken: AuthToken
    let refreshToken: AuthToken?
    let userId: Int
    let expiresAt: String?
    
    var expiryDate: Date? {
        guard let expiresAt = expiresAt else { return nil }
        return ISO8601DateFormatter().date(from: expiresAt)
    }
}

// MARK: - Token Manager Extensions

extension TokenManager {
    
    // Convenience method for logout
    func logout() {
        clearTokens()
        
        // Post logout notification
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
        
        Logger.shared.info("User logged out", category: "auth")
    }
    
    // Check if user session is still valid
    func validateSession() async -> Bool {
        if isTokenValid() {
            return true
        }
        
        // Try to refresh token
        let refreshedToken = await refreshTokenIfNeeded()
        return refreshedToken != nil
    }
    
    // Force token refresh (for testing or manual refresh)
    func forceRefreshToken() async -> String? {
        refreshTask?.cancel()
        refreshTask = nil
        
        return await performTokenRefresh()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
    static let tokenDidRefresh = Notification.Name("tokenDidRefresh")
    static let tokenRefreshFailed = Notification.Name("tokenRefreshFailed")
}

// MARK: - Token Storage Security

extension TokenManager {
    
    // Verify keychain accessibility
    func verifyKeychainAccess() -> Bool {
        do {
            let testKey = "test_key"
            let testValue = "test_value"
            
            try keychain.set(testValue, key: testKey)
            let retrievedValue = try keychain.get(testKey)
            try keychain.remove(testKey)
            
            return retrievedValue == testValue
        } catch {
            Logger.shared.error("Keychain access verification failed", error: error, category: "auth")
            return false
        }
    }
    
    // Migration helper for old token storage
    func migrateFromUserDefaults() {
        // Check if tokens exist in UserDefaults (legacy storage)
        if let legacyToken = UserDefaults.standard.string(forKey: "legacy_access_token"),
           let legacyUserIdString = UserDefaults.standard.string(forKey: "legacy_user_id"),
           let legacyUserId = Int(legacyUserIdString) {
            
            // Migrate to keychain
            saveTokens(
                accessToken: legacyToken,
                userId: legacyUserId
            )
            
            // Remove from UserDefaults
            UserDefaults.standard.removeObject(forKey: "legacy_access_token")
            UserDefaults.standard.removeObject(forKey: "legacy_user_id")
            
            Logger.shared.info("Migrated tokens from UserDefaults to Keychain", category: "auth")
        }
    }
}

