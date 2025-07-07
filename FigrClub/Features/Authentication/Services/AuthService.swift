//
//  AuthService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol AuthServiceProtocol {
    func login(_ request: LoginRequest) async throws -> AuthResponse
    func register(_ request: RegisterRequest) async throws -> AuthResponse
    func logout() async throws
    func refreshToken() async throws -> AuthResponse
    func getCurrentUser() async throws -> User
}

final class AuthService: AuthServiceProtocol {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        Logger.info("Attempting login for email: \(request.email)")
        
        let parameters: [String: Any] = [
            "email": request.email,
            "password": request.password
        ]
        
        do {
            let response: AuthResponse = try await apiService.request(.login, parameters: parameters)
            Logger.info("Login successful for user: \(response.user.username)")
            return response
        } catch {
            Logger.error("Login failed: \(error)")
            throw error
        }
    }
    
    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        Logger.info("Attempting registration for email: \(request.email)")
        
        var parameters: [String: Any] = [
            "email": request.email,
            "password": request.password,
            "username": request.username
        ]
        
        if let fullName = request.fullName {
            parameters["fullName"] = fullName
        }
        
        do {
            let response: AuthResponse = try await apiService.request(.register, parameters: parameters)
            Logger.info("Registration successful for user: \(response.user.username)")
            return response
        } catch {
            Logger.error("Registration failed: \(error)")
            throw error
        }
    }
    
    func logout() async throws {
        Logger.info("Attempting logout")
        
        do {
            let _: EmptyResponse = try await apiService.request(.logout, parameters: nil)
            Logger.info("Logout successful")
        } catch {
            Logger.error("Logout failed: \(error)")
            throw error
        }
    }
    
    func refreshToken() async throws -> AuthResponse {
        Logger.info("Attempting token refresh")
        
        do {
            let response: AuthResponse = try await apiService.request(.refreshToken, parameters: nil)
            Logger.info("Token refresh successful")
            return response
        } catch {
            Logger.error("Token refresh failed: \(error)")
            throw error
        }
    }
    
    func getCurrentUser() async throws -> User {
        Logger.info("Fetching current user profile")
        
        do {
            let user: User = try await apiService.request(.profile, parameters: nil)
            Logger.info("User profile fetched: \(user.username)")
            return user
        } catch {
            Logger.error("Failed to fetch user profile: \(error)")
            throw error
        }
    }
}

// MARK: - Empty Response Model
struct EmptyResponse: Codable {}

