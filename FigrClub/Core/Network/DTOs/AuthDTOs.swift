//
//  AuthDTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Auth DTOs
struct LoginRequestDTO: BaseDTO {
    let email: String
    let password: String
}

struct AuthDataDTO: BaseDTO {
    let authToken: AuthTokenDTO
    let userId: Int
    let email: String
}

typealias AuthResponseDTO = ApiResponseDTO<AuthDataDTO>

struct AuthTokenDTO: BaseDTO {
    let id: Int
    let token: String
}

struct RegisterRequestDTO: BaseDTO {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let username: String
    let legalAcceptances: [LegalAcceptanceDTO]
    let consents: [ConsentDTO]
}

struct RegisterDataDTO: BaseDTO {
    let userId: Int
    let email: String
    let fullName: String
    let emailVerified: Bool
    let emailSent: Bool
}

typealias RegisterResponseDTO = ApiResponseDTO<RegisterDataDTO>

struct LegalAcceptanceDTO: BaseDTO {
    let documentId: Int
    let acceptedAt: String
}

struct ConsentDTO: BaseDTO {
    let consentType: String
    let isGranted: Bool
}
