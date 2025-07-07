//
//  TokenManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import KeychainAccess

final class TokenManager: ObservableObject, @unchecked Sendable {
    
    private let keychain: Keychain
    private let queue = DispatchQueue(label: "com.figrclub.tokenmanager", qos: .userInitiated)
    
    // Published properties para UI
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentToken: String?
    
    // MARK: - Initializer público (sin singleton)
    init() {
        self.keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "com.emerbv.FigrClub")
            .accessibility(.whenUnlockedThisDeviceOnly)
        
        // Initialize authentication status
        Task {
            await self.checkAuthenticationStatus()
        }
    }
    
    // MARK: - Thread-safe Public Methods
    
    func saveToken(_ token: String) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    try self.keychain.set(token, key: AppConfig.Auth.tokenKey)
                    
                    DispatchQueue.main.async {
                        self.currentToken = token
                        self.isAuthenticated = true
                    }
                    
                    Logger.info("Token saved successfully")
                } catch {
                    Logger.error("Failed to save token: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    func saveRefreshToken(_ refreshToken: String) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    try self.keychain.set(refreshToken, key: AppConfig.Auth.refreshTokenKey)
                    Logger.info("Refresh token saved successfully")
                } catch {
                    Logger.error("Failed to save refresh token: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    func getToken() async -> String? {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let token = try self.keychain.get(AppConfig.Auth.tokenKey)
                    continuation.resume(returning: token)
                } catch {
                    Logger.error("Failed to retrieve token: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func getRefreshToken() async -> String? {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let refreshToken = try self.keychain.get(AppConfig.Auth.refreshTokenKey)
                    continuation.resume(returning: refreshToken)
                } catch {
                    Logger.error("Failed to retrieve refresh token: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func clearTokens() async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    try self.keychain.remove(AppConfig.Auth.tokenKey)
                    try self.keychain.remove(AppConfig.Auth.refreshTokenKey)
                    
                    DispatchQueue.main.async {
                        self.currentToken = nil
                        self.isAuthenticated = false
                    }
                    
                    Logger.info("Tokens cleared successfully")
                } catch {
                    Logger.error("Failed to clear tokens: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    func checkAuthenticationStatus() async {
        let token = await getToken()
        
        await MainActor.run {
            self.isAuthenticated = token != nil
            self.currentToken = token
        }
        
        Logger.info("Authentication status checked: \(isAuthenticated)")
    }
    
    // MARK: - Synchronous methods for backward compatibility
    
    /// Synchronous token check (use sparingly, prefer async version)
    func hasValidToken() -> Bool {
        do {
            return try keychain.contains(AppConfig.Auth.tokenKey)
        } catch {
            Logger.error("Error checking token existence: \(error)")
            return false
        }
    }
}
