//
//  TokenManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import KeychainAccess

final class TokenManager: @unchecked Sendable {
    
    private let keychain: Keychain
    private let queue = DispatchQueue(label: "com.figrclub.tokenmanager", qos: .userInitiated)
    
    // MARK: - Keys for storage
    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "current_user_id"
    }
    
    // MARK: - Initializer
    init() {
        self.keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "com.emerbv.FigrClub")
            .accessibility(.whenUnlockedThisDeviceOnly)
        
        Logger.debug("🔧 TokenManager: Initialized (Storage Only)")
    }
    
    // MARK: - Core Token Operations
    
    func saveToken(_ token: String) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    try self.keychain.set(token, key: Keys.accessToken)
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
                    try self.keychain.remove(Keys.userId)
                    
                    Logger.info("✅ TokenManager: All tokens cleared")
                } catch {
                    Logger.error("❌ TokenManager: Failed to clear tokens: \(error)")
                }
                
                continuation.resume()
            }
        }
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
    
    /// Verificación simple de credenciales válidas
    func hasValidCredentials() async -> Bool {
        let hasToken = await getToken() != nil
        let hasUserId = await getCurrentUserId() != nil
        let result = hasToken && hasUserId
        
        Logger.debug("🔍 TokenManager: Credentials check - Token: \(hasToken), UserId: \(hasUserId), Valid: \(result)")
        return result
    }
    
}
