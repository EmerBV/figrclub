//
//  AuthService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol: Sendable {
    func login(_ request: LoginRequest) async throws -> AuthResponse
    func register(_ request: RegisterRequest) async throws -> RegisterResponse
    func logout() async throws
    func getCurrentUser() async throws -> UserResponse
    func refreshToken() async throws -> AuthResponse
}

// MARK: - Auth Service Implementation
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    private let networkDispatcher: NetworkDispatcherProtocol
    
    // MARK: - Initialization
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
        Logger.debug("🔧 AuthService: Initialized with NetworkDispatcher")
    }
    
    // MARK: - AuthServiceProtocol Implementation
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        let endpoint = AuthEndpoints.login(request: request)
        Logger.debug("🔐 AuthService: Calling login endpoint for user: \(request.email)")
        
        do {
            let response: AuthResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("✅ AuthService: Login successful for user: \(request.email)")
            return response
        } catch {
            Logger.error("❌ AuthService: Login failed for user: \(request.email) - Error: \(error)")
            throw error
        }
    }
    
    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        let endpoint = AuthEndpoints.register(request: request)
        Logger.debug("📝 AuthService: Calling register endpoint for user: \(request.email)")
        
        do {
            let response: RegisterResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("✅ AuthService: Registration successful for user: \(request.email)")
            return response
        } catch {
            Logger.error("❌ AuthService: Registration failed for user: \(request.email) - Error: \(error)")
            throw error
        }
    }
    
    func logout() async throws {
        let endpoint = AuthEndpoints.logout
        Logger.debug("🚪 AuthService: Calling logout endpoint")
        
        do {
            let _: ApiResponse<EmptyResponse> = try await networkDispatcher.dispatch(endpoint)
            Logger.info("✅ AuthService: Logout successful")
        } catch {
            Logger.error("❌ AuthService: Logout failed - Error: \(error)")
            throw error
        }
    }
    
    func getCurrentUser() async throws -> UserResponse {
        let endpoint = UserEndpoints.getCurrentUser
        Logger.debug("👤 AuthService: Getting current user")
        
        do {
            let response: UserResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("✅ AuthService: Got current user successfully")
            return response
        } catch {
            Logger.error("❌ AuthService: Failed to get current user - Error: \(error)")
            throw error
        }
    }
    
    func refreshToken() async throws -> AuthResponse {
        let endpoint = AuthEndpoints.refreshToken
        Logger.debug("🔄 AuthService: Refreshing token")
        
        do {
            let response: AuthResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("✅ AuthService: Token refresh successful")
            return response
        } catch {
            Logger.error("❌ AuthService: Token refresh failed - Error: \(error)")
            throw error
        }
    }
}

