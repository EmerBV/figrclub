//
//  TokenManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import KeychainAccess

@MainActor
final class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    private let keychain: Keychain
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentToken: String?
    
    private init() {
        self.keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "com.emerbv.FigrClub")
            .accessibility(.whenUnlockedThisDeviceOnly)
        
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func saveToken(_ token: String) async {
        do {
            try keychain.set(token, key: AppConfig.Auth.tokenKey)
            currentToken = token
            isAuthenticated = true
            Logger.info("Token saved successfully")
        } catch {
            Logger.error("Failed to save token: \(error)")
        }
    }
    
    func saveRefreshToken(_ refreshToken: String) async {
        do {
            try keychain.set(refreshToken, key: AppConfig.Auth.refreshTokenKey)
            Logger.info("Refresh token saved successfully")
        } catch {
            Logger.error("Failed to save refresh token: \(error)")
        }
    }
    
    func getToken() async -> String? {
        do {
            let token = try keychain.get(AppConfig.Auth.tokenKey)
            return token
        } catch {
            Logger.error("Failed to retrieve token: \(error)")
            return nil
        }
    }
    
    func getRefreshToken() async -> String? {
        do {
            let refreshToken = try keychain.get(AppConfig.Auth.refreshTokenKey)
            return refreshToken
        } catch {
            Logger.error("Failed to retrieve refresh token: \(error)")
            return nil
        }
    }
    
    func clearTokens() async {
        do {
            try keychain.remove(AppConfig.Auth.tokenKey)
            try keychain.remove(AppConfig.Auth.refreshTokenKey)
            currentToken = nil
            isAuthenticated = false
            Logger.info("Tokens cleared successfully")
        } catch {
            Logger.error("Failed to clear tokens: \(error)")
        }
    }
    
    func checkAuthenticationStatus() async {
        let token = await getToken()
        isAuthenticated = token != nil
        currentToken = token
        Logger.info("Authentication status checked: \(isAuthenticated)")
    }
}
