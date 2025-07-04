//
//  AuthService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

protocol AuthServiceProtocol {
    func login(request: LoginRequest) async throws -> AuthResponse
}

final class AuthService: AuthServiceProtocol {
    func login(request: LoginRequest) async throws -> AuthResponse {
        <#code#>
    }
}
