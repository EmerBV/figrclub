//
//  NetworkError.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

// MARK: - Enhanced Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case badRequest(APIError?)
    case serverError(APIError?)
    case decodingError(DecodingError)
    case noInternetConnection
    case timeout
    case rateLimited(retryAfter: TimeInterval?)
    case maintenance
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .unauthorized:
            return "No autorizado. Por favor inicia sesión nuevamente"
        case .forbidden:
            return "Acceso prohibido"
        case .notFound:
            return "Recurso no encontrado"
        case .badRequest(let apiError):
            return apiError?.message ?? "Solicitud incorrecta"
        case .serverError(let apiError):
            return apiError?.message ?? "Error del servidor"
        case .decodingError(let decodingError):
            return "Error al procesar la respuesta: \(decodingError.localizedDescription)"
        case .noInternetConnection:
            return "Sin conexión a internet"
        case .timeout:
            return "Tiempo de espera agotado"
        case .rateLimited(let retryAfter):
            let retryMessage = retryAfter.map { " Reintentar en \(Int($0)) segundos." } ?? ""
            return "Demasiadas solicitudes.\(retryMessage)"
        case .maintenance:
            return "Servicio en mantenimiento. Intenta más tarde"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .timeout, .noInternetConnection, .serverError, .rateLimited:
            return true
        case .unauthorized, .forbidden, .notFound, .badRequest, .decodingError:
            return false
        case .invalidURL, .invalidResponse, .maintenance:
            return false
        case .unknown:
            return true
        }
    }
}

// MARK: - Network Error Extensions for Enhanced Endpoint
extension NetworkError {
    
    /// Determine if error is retryable based on endpoint's retry policy
    func isRetryableForEndpoint(_ endpoint: APIEndpoint) -> Bool {
        switch self {
        case .badRequest, .unauthorized, .forbidden, .notFound:
            return false
        case .serverError, .timeout, .noInternetConnection, .rateLimited:
            return endpoint.retryPolicy.maxRetries > 0
        case .invalidURL, .invalidResponse, .decodingError:
            return false
        case .maintenance:
            return endpoint.retryPolicy.maxRetries > 0
        case .unknown:
            return endpoint.retryPolicy.maxRetries > 0
        }
    }
    
    /// Get the HTTP status code if this is an HTTP error
    var httpStatusCode: Int? {
        switch self {
        case .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .serverError:
            return 500
        case .rateLimited:
            return 429
        default:
            return nil
        }
    }
}
