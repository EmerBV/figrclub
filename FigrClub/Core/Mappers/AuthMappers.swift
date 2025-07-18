//
//  AuthMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Auth Mappers
struct AuthMappers {
    
    static func toAuthResponse(from dto: AuthResponseDTO) -> AuthResponse {
        return GenericResponseMapper.mapResponse(from: dto) { authDataDTO in
            AuthData(
                authToken: AuthToken(
                    id: authDataDTO.authToken.id,
                    token: authDataDTO.authToken.token
                ),
                userId: authDataDTO.userId,
                email: authDataDTO.email
            )
        }
    }
    
    static func toRegisterResponse(from dto: RegisterResponseDTO) -> RegisterResponse {
        return GenericResponseMapper.mapResponse(from: dto) { registerDataDTO in
            RegisterData(
                userId: registerDataDTO.userId,
                email: registerDataDTO.email,
                fullName: registerDataDTO.fullName,
                emailVerified: registerDataDTO.emailVerified,
                emailSent: registerDataDTO.emailSent
            )
        }
    }
}
