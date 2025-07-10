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
    @Published private(set) var currentUserId: Int?  // ✅ Nueva propiedad
    
    // MARK: - Keys for storage
    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "current_user_id"  // ✅ Nueva clave
    }
    
    // MARK: - Initializer
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
                    try self.keychain.set(token, key: Keys.accessToken)
                    
                    DispatchQueue.main.async {
                        self.currentToken = token
                        self.isAuthenticated = true
                    }
                    
                    Logger.info("✅ TokenManager: Token saved successfully")
                } catch {
                    Logger.error("❌ TokenManager: Failed to save token: \(error)")
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
                    try self.keychain.set(refreshToken, key: Keys.refreshToken)
                    Logger.info("✅ TokenManager: Refresh token saved successfully")
                } catch {
                    Logger.error("❌ TokenManager: Failed to save refresh token: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    func saveUserId(_ userId: Int) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    try self.keychain.set(String(userId), key: Keys.userId)
                    
                    DispatchQueue.main.async {
                        self.currentUserId = userId
                    }
                    
                    Logger.info("✅ TokenManager: UserId saved successfully: \(userId)")
                } catch {
                    Logger.error("❌ TokenManager: Failed to save userId: \(error)")
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
                    let token = try self.keychain.get(Keys.accessToken)
                    continuation.resume(returning: token)
                } catch {
                    Logger.error("❌ TokenManager: Failed to retrieve token: \(error)")
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
                    let refreshToken = try self.keychain.get(Keys.refreshToken)
                    continuation.resume(returning: refreshToken)
                } catch {
                    Logger.error("❌ TokenManager: Failed to retrieve refresh token: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func getCurrentUserId() async -> Int? {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    guard let userIdString = try self.keychain.get(Keys.userId),
                          let userId = Int(userIdString) else {
                        Logger.debug("🔍 TokenManager: No valid userId found")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    Logger.debug("🆔 TokenManager: UserId retrieved: \(userId)")
                    continuation.resume(returning: userId)
                } catch {
                    Logger.error("❌ TokenManager: Failed to retrieve userId: \(error)")
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
                    try self.keychain.remove(Keys.accessToken)
                    try self.keychain.remove(Keys.refreshToken)
                    try self.keychain.remove(Keys.userId)  // ✅ También limpiar userId
                    
                    DispatchQueue.main.async {
                        self.currentToken = nil
                        self.currentUserId = nil
                        self.isAuthenticated = false
                    }
                    
                    Logger.info("✅ TokenManager: All tokens cleared")
                } catch {
                    Logger.error("❌ TokenManager: Failed to clear tokens: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    func checkAuthenticationStatus() async {
        let token = await getToken()
        let userId = await getCurrentUserId()
        
        await MainActor.run {
            self.isAuthenticated = token != nil && userId != nil
            self.currentToken = token
            self.currentUserId = userId
        }
        
        Logger.info("📊 TokenManager: Authentication status checked - Authenticated: \(isAuthenticated), UserId: \(userId?.description ?? "nil")")
    }
    
    // MARK: - Convenience Methods
    
    /// Guarda tanto el token como el userId en una sola operación
    func saveAuthData(token: String, userId: Int, refreshToken: String? = nil) async {
        await saveToken(token)
        await saveUserId(userId)
        
        if let refreshToken = refreshToken {
            await saveRefreshToken(refreshToken)
        }
        
        Logger.info("✅ TokenManager: Auth data saved (token + userId: \(userId))")
    }
    
    // MARK: - Synchronous methods for backward compatibility
    
    /// Synchronous token check (use sparingly, prefer async version)
    func hasValidToken() -> Bool {
        do {
            let hasToken = try keychain.contains(Keys.accessToken)
            let hasUserId = try keychain.contains(Keys.userId)
            return hasToken && hasUserId
        } catch {
            Logger.error("❌ TokenManager: Error checking token existence: \(error)")
            return false
        }
    }
}
