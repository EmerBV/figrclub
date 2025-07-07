//
//  APIError.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case authenticationFailed
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case usernameAlreadyExists
    case invalidResponse
    case decodingError(Error)
    case serverError(Int)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Error de autenticación"
        case .invalidCredentials:
            return "Credenciales inválidas"
        case .userNotFound:
            return "Usuario no encontrado"
        case .emailAlreadyExists:
            return "El email ya está registrado"
        case .usernameAlreadyExists:
            return "El nombre de usuario ya existe"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .decodingError:
            return "Error al procesar la respuesta"
        case .serverError(let code):
            return "Error del servidor (código: \(code))"
        case .unknown:
            return "Error desconocido"
        }
    }
}
