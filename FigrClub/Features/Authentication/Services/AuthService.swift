//
//  AuthService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

// MARK: - Auth Service Protocol (Final)
protocol AuthServiceProtocol: Sendable {
    func login(_ request: LoginRequest) async throws -> AuthResponse
    func register(_ request: RegisterRequest) async throws -> RegisterResponse
    func logout() async throws
    func getCurrentUser(userId: Int) async throws -> UserResponse
    func refreshToken() async throws -> AuthResponse
}

// MARK: - Auth Service Implementation (Final)
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    private let networkDispatcher: NetworkDispatcherProtocol
    
    // MARK: - Initialization
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
        Logger.debug("🔧 AuthService: Initialized with NetworkDispatcher and Generic DTOs")
    }
    
    // MARK: - AuthServiceProtocol Implementation
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        // Convert domain model to DTO
        let requestDTO = LoginRequestDTO(
            email: request.email,
            password: request.password
        )
        
        let endpoint = AuthEndpoints.login(request: requestDTO)
        Logger.debug("🔐 AuthService: Calling login endpoint for user: \(request.email)")
        
        do {
            // ✅ Get generic DTO response from network
            let responseDTO: AuthResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            // ✅ Convert DTO to domain model using generic mapper
            let response = AuthMapper.toDomainModel(from: responseDTO)
            
            Logger.info("✅ AuthService: Login successful for user: \(request.email)")
            return response
        } catch {
            Logger.error("❌ AuthService: Login failed for user: \(request.email) - Error: \(error)")
            throw error
        }
    }
    
    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        // Convert domain model to DTO
        let requestDTO = RegisterRequestDTO(
            firstName: request.firstName,
            lastName: request.lastName,
            email: request.email,
            password: request.password,
            username: request.username,
            userType: request.userType,
            legalAcceptances: request.legalAcceptances.map {
                LegalAcceptanceDTO(
                    documentType: $0.documentType,
                    acceptedAt: DateFormatter.iso8601.string(from: $0.acceptedAt)
                )
            },
            consents: request.consents.map {
                ConsentDTO(
                    consentType: $0.consentType,
                    isGranted: $0.isGranted
                )
            }
        )
        
        let endpoint = AuthEndpoints.register(request: requestDTO)
        Logger.debug("📝 AuthService: Calling register endpoint for user: \(request.email)")
        
        do {
            // ✅ Get generic DTO response from network
            let responseDTO: RegisterResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            // ✅ Convert DTO to domain model using generic mapper
            let response = RegisterMapper.toDomainModel(from: responseDTO)
            
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
            // ✅ Using generic empty response
            let _: EmptyResponseDTO = try await networkDispatcher.dispatch(endpoint)
            Logger.info("✅ AuthService: Logout successful")
        } catch {
            Logger.error("❌ AuthService: Logout failed - Error: \(error)")
            throw error
        }
    }
    
    func getCurrentUser(userId: Int) async throws -> UserResponse {
        let endpoint = UserEndpoints.getCurrentUser(userId: userId)
        Logger.debug("👤 AuthService: Getting current user with ID: \(userId)")
        
        do {
            // ✅ Get generic DTO response from network
            let responseDTO: UserResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            // ✅ Convert DTO to domain model using generic mapper
            let response = UserResponseMapper.toDomainModel(from: responseDTO)
            
            Logger.info("✅ AuthService: Got current user successfully for userId: \(userId)")
            return response
        } catch {
            Logger.error("❌ AuthService: Failed to get current user with ID \(userId) - Error: \(error)")
            throw error
        }
    }
    
    func refreshToken() async throws -> AuthResponse {
        let endpoint = AuthEndpoints.refreshToken
        Logger.debug("🔄 AuthService: Refreshing token")
        
        do {
            // ✅ Get generic DTO response from network
            let responseDTO: AuthResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            // ✅ Convert DTO to domain model using generic mapper
            let response = AuthMapper.toDomainModel(from: responseDTO)
            
            Logger.info("✅ AuthService: Token refresh successful")
            return response
        } catch {
            Logger.error("❌ AuthService: Token refresh failed - Error: \(error)")
            throw error
        }
    }
}

