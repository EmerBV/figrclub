//
//  APIError.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

// MARK: - API Error
struct APIError: Error, Codable {
    let message: String
    let code: String
    let timestamp: String
    let statusCode: Int?
    let details: [String: String]?
    
    var localizedDescription: String {
        return message
    }
    
    var isNetworkError: Bool {
        return code.hasPrefix("NETWORK_") || statusCode == nil
    }
    
    var isAuthenticationError: Bool {
        return statusCode == 401 || code == "UNAUTHORIZED"
    }
    
    var isServerError: Bool {
        return (statusCode ?? 0) >= 500
    }
    
    var isClientError: Bool {
        return (statusCode ?? 0) >= 400 && (statusCode ?? 0) < 500
    }
}

// MARK: - Error Recovery Strategy
enum ErrorRecoveryStrategy {
    case retry(maxAttempts: Int, delay: TimeInterval)
    case refreshTokenAndRetry
    case showError
    case silent
    case logout
}

// MARK: - Error Handler Protocol
protocol ErrorHandler {
    func handle(_ error: Error) -> ErrorRecoveryStrategy
    func getUserFriendlyMessage(for error: Error) -> String
}

// MARK: - Default Error Handler Implementation
final class DefaultErrorHandler: ErrorHandler {
    
    func handle(_ error: Error) -> ErrorRecoveryStrategy {
        if let apiError = error as? APIError {
            return handleAPIError(apiError)
        }
        
        if let urlError = error as? URLError {
            return handleURLError(urlError)
        }
        
        // Default strategy for unknown errors
        return .showError
    }
    
    func getUserFriendlyMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return getUserFriendlyAPIErrorMessage(apiError)
        }
        
        if let urlError = error as? URLError {
            return getUserFriendlyURLErrorMessage(urlError)
        }
        
        if let useCaseError = error as? UseCaseError {
            return useCaseError.errorDescription ?? "Error desconocido"
        }
        
        return "Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo."
    }
    
    // MARK: - Private Methods
    
    private func handleAPIError(_ error: APIError) -> ErrorRecoveryStrategy {
        switch error.statusCode {
        case 401:
            return .refreshTokenAndRetry
        case 403:
            return .showError
        case 404:
            return .showError
        case 429: // Rate limit
            return .retry(maxAttempts: 3, delay: 2.0)
        case 500...599:
            return .retry(maxAttempts: 2, delay: 1.0)
        default:
            return .showError
        }
    }
    
    private func handleURLError(_ error: URLError) -> ErrorRecoveryStrategy {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .retry(maxAttempts: 3, delay: 2.0)
        case .timedOut:
            return .retry(maxAttempts: 2, delay: 1.0)
        case .cannotFindHost, .cannotConnectToHost:
            return .showError
        default:
            return .showError
        }
    }
    
    private func getUserFriendlyAPIErrorMessage(_ error: APIError) -> String {
        switch error.statusCode {
        case 400:
            return "Los datos enviados no son válidos. Verifica la información."
        case 401:
            return "Tu sesión ha expirado. Por favor, inicia sesión nuevamente."
        case 403:
            return "No tienes permisos para realizar esta acción."
        case 404:
            return "El recurso solicitado no fue encontrado."
        case 409:
            return "Conflicto con el estado actual. Por favor, actualiza e inténtalo de nuevo."
        case 429:
            return "Demasiadas solicitudes. Por favor, espera un momento e inténtalo de nuevo."
        case 500...599:
            return "Error del servidor. Nuestro equipo ha sido notificado."
        default:
            return error.message
        }
    }
    
    private func getUserFriendlyURLErrorMessage(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "Sin conexión a internet. Verifica tu conexión e inténtalo de nuevo."
        case .timedOut:
            return "La solicitud tardó demasiado. Verifica tu conexión e inténtalo de nuevo."
        case .cannotFindHost:
            return "No se puede encontrar el servidor. Verifica tu conexión."
        case .cannotConnectToHost:
            return "No se puede conectar al servidor. Inténtalo más tarde."
        case .networkConnectionLost:
            return "Se perdió la conexión. Verifica tu red e inténtalo de nuevo."
        default:
            return "Error de conexión. Por favor, inténtalo de nuevo."
        }
    }
}

// MARK: - Error Response
struct APIErrorResponse: Codable {
    let message: String
    let code: String?
    let timestamp: String
    let status: Int?
}
