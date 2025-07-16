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
    func getCurrentUser(userId: Int) async throws -> UserResponse
    func refreshToken() async throws -> AuthResponse
}

// MARK: - Auth Service Implementation
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    private let networkDispatcher: NetworkDispatcherProtocol
    
    // MARK: - Initialization
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
        Logger.debug("🔧 AuthService: Initialized with simplified mappers")
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
            let responseDTO: AuthResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            let response = AuthMappers.toAuthResponse(from: responseDTO)
            
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
            legalAcceptances: request.legalAcceptances.map {
                LegalAcceptanceDTO(
                    documentId: $0.documentId,
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
        Logger.debug("🔍 AuthService: Password validation - Length: \(request.password.count), HasLetter: \(request.password.rangeOfCharacter(from: .letters) != nil), HasNumber: \(request.password.rangeOfCharacter(from: .decimalDigits) != nil), HasSpecial: \(request.password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil)")
        
        // Debug: Log the request structure
        if let jsonData = try? JSONEncoder().encode(requestDTO),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            Logger.debug("📄 AuthService: Request JSON structure: \(jsonString)")
        }
        
        do {
            let responseDTO: RegisterResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            let response = AuthMappers.toRegisterResponse(from: responseDTO)
            
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
            let responseDTO: UserResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            let response = UserMappers.toDomainModel(from: responseDTO)
            
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
            let responseDTO: AuthResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            let response = AuthMappers.toAuthResponse(from: responseDTO)
            
            Logger.info("✅ AuthService: Token refresh successful")
            return response
        } catch {
            Logger.error("❌ AuthService: Token refresh failed - Error: \(error)")
            throw error
        }
    }
}

