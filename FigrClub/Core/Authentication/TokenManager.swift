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
    
    @Published var isAuthenticated = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Configurar keychain con service específico para la app
        self.keychain = Keychain(service: "com.emerbv.FigrClub")
            .accessibility(.whenUnlockedThisDeviceOnly)
            .synchronizable(false)
        
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    func saveTokens(accessToken: String, refreshToken: String? = nil, userId: Int) {
        do {
            try keychain.set(accessToken, key: accessTokenKey)
            
            if let refreshToken = refreshToken {
                try keychain.set(refreshToken, key: refreshTokenKey)
            }
            
            try keychain.set(String(userId), key: userIdKey)
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
            
#if DEBUG
            print("✅ Tokens saved successfully for user: \(userId)")
#endif
            
        } catch {
#if DEBUG
            print("❌ Failed to save tokens: \(error)")
#endif
        }
    }
    
    func getAccessToken() -> String? {
        do {
            return try keychain.get(accessTokenKey)
        } catch {
#if DEBUG
            print("❌ Failed to get access token: \(error)")
#endif
            return nil
        }
    }
    
    func getRefreshToken() -> String? {
        do {
            return try keychain.get(refreshTokenKey)
        } catch {
#if DEBUG
            print("❌ Failed to get refresh token: \(error)")
#endif
            return nil
        }
    }
    
    func getUserId() -> Int? {
        do {
            guard let userIdString = try keychain.get(userIdKey),
                  let userId = Int(userIdString) else {
                return nil
            }
            return userId
        } catch {
#if DEBUG
            print("❌ Failed to get user ID: \(error)")
#endif
            return nil
        }
    }
    
    func clearTokens() {
        do {
            try keychain.remove(accessTokenKey)
            try keychain.remove(refreshTokenKey)
            try keychain.remove(userIdKey)
            
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
            
#if DEBUG
            print("✅ Tokens cleared successfully")
#endif
            
        } catch {
#if DEBUG
            print("❌ Failed to clear tokens: \(error)")
#endif
        }
    }
    
    func refreshAccessToken() async -> Result<String, APIError> {
        guard let refreshToken = getRefreshToken() else {
            clearTokens()
            return .failure(APIError(
                message: "No refresh token available",
                code: "NO_REFRESH_TOKEN",
                timestamp: ISO8601DateFormatter().string(from: Date())
            ))
        }
        
        do {
            let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await APIService.shared
                .request(endpoint: .refreshToken, body: refreshRequest)
                .async()
            
            // Save new tokens
            saveTokens(
                accessToken: response.authToken.token,
                refreshToken: refreshToken, // Keep the same refresh token unless API provides a new one
                userId: response.userId
            )
            
            return .success(response.authToken.token)
            
        } catch {
            clearTokens()
            
            let apiError = error as? APIError ?? APIError(
                message: "Failed to refresh token",
                code: "REFRESH_FAILED",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            return .failure(apiError)
        }
    }
    
    // MARK: - Private Methods
    
    private func checkAuthenticationStatus() {
        let hasAccessToken = getAccessToken() != nil
        let hasUserId = getUserId() != nil
        
        DispatchQueue.main.async {
            self.isAuthenticated = hasAccessToken && hasUserId
        }
    }
    
    // MARK: - Token Validation
    
    func isTokenExpired() -> Bool {
        // Simple check - if no token exists, consider it expired
        guard let token = getAccessToken() else { return true }
        
        // TODO: Implement JWT token expiration check
        // For now, assume token is valid if it exists
        // You can decode the JWT and check the 'exp' claim
        
        return false
    }
    
    func shouldRefreshToken() -> Bool {
        // TODO: Implement logic to check if token should be refreshed
        // (e.g., if it expires in less than 5 minutes)
        return isTokenExpired()
    }
    
    // MARK: - Biometric Authentication Support
    
    func saveTokensWithBiometrics(accessToken: String, refreshToken: String? = nil, userId: Int) {
        do {
            let biometricKeychain = keychain.accessibility(.whenUnlockedThisDeviceOnly, authenticationPolicy: .biometryAny)
            
            try biometricKeychain.set(accessToken, key: accessTokenKey)
            
            if let refreshToken = refreshToken {
                try biometricKeychain.set(refreshToken, key: refreshTokenKey)
            }
            
            try biometricKeychain.set(String(userId), key: userIdKey)
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
            
#if DEBUG
            print("✅ Tokens saved with biometric protection for user: \(userId)")
#endif
            
        } catch {
#if DEBUG
            print("❌ Failed to save tokens with biometrics: \(error)")
#endif
            // Fallback to regular save
            saveTokens(accessToken: accessToken, refreshToken: refreshToken, userId: userId)
        }
    }
    
    // MARK: - Debug Methods
    
#if DEBUG
    func debugPrintKeychain() {
        print("🔑 Keychain Debug Info:")
        print("- Has Access Token: \(getAccessToken() != nil)")
        print("- Has Refresh Token: \(getRefreshToken() != nil)")
        print("- User ID: \(getUserId() ?? 0)")
        print("- Is Authenticated: \(isAuthenticated)")
    }
    
    func clearAllKeychainData() {
        do {
            try keychain.removeAll()
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
            print("✅ All keychain data cleared")
        } catch {
            print("❌ Failed to clear keychain: \(error)")
        }
    }
#endif
}

// MARK: - Supporting Models
struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

