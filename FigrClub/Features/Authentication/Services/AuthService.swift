//
//  AuthService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol AuthServiceProtocol: Sendable {
    func login(_ request: LoginRequest) async throws -> AuthResponse
    func register(_ request: RegisterRequest) async throws -> RegisterResponse
    func logout() async throws
    func getCurrentUser() async throws -> UserResponse
    func refreshToken() async throws -> AuthResponse
}

final class AuthService: AuthServiceProtocol {
    private let networkDispatcher: APIServiceProtocol
    
    init(networkDispatcher: APIServiceProtocol) {
        self.networkDispatcher = networkDispatcher
    }
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        let endpoint = AuthEndpoints.login(request: request)
        Logger.debug("AuthService: Calling login endpoint")
        
        do {
            let response: AuthResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("AuthService: Login successful")
            return response
        } catch {
            Logger.error("AuthService: Login failed with error: \(error)")
            throw error
        }
    }
    
    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        let endpoint = AuthEndpoints.register(request: request)
        Logger.debug("AuthService: Calling register endpoint")
        
        do {
            let response: RegisterResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("AuthService: Registration successful")
            return response
        } catch {
            Logger.error("AuthService: Registration failed with error: \(error)")
            throw error
        }
    }
    
    func logout() async throws {
        let endpoint = AuthEndpoints.logout
        Logger.debug("AuthService: Calling logout endpoint")
        
        do {
            let _: ApiResponse<EmptyResponse> = try await networkDispatcher.dispatch(endpoint)
            Logger.info("AuthService: Logout successful")
        } catch {
            Logger.error("AuthService: Logout failed with error: \(error)")
            throw error
        }
    }
    
    func getCurrentUser() async throws -> UserResponse {
        let endpoint = UserEndpoints.getCurrentUser
        Logger.debug("AuthService: Getting current user")
        
        do {
            let response: UserResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("AuthService: Got current user successfully")
            return response
        } catch {
            Logger.error("AuthService: Failed to get current user: \(error)")
            throw error
        }
    }
    
    func refreshToken() async throws -> AuthResponse {
        let endpoint = AuthEndpoints.refreshToken
        Logger.debug("AuthService: Refreshing token")
        
        do {
            let response: AuthResponse = try await networkDispatcher.dispatch(endpoint)
            Logger.info("AuthService: Token refresh successful")
            return response
        } catch {
            Logger.error("AuthService: Token refresh failed with error: \(error)")
            throw error
        }
    }
}

