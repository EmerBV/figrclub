//
//  NetworkError.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

// MARK: - Network Errors
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
    
    // MARK: - User-Friendly Messages for UI
    var userFriendlyMessage: String {
        switch self {
        case .invalidURL:
            return "Error de configuración. Intenta más tarde"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .unauthorized:
            return "Sesión expirada. Inicia sesión nuevamente"
        case .forbidden:
            return "No tienes permisos para realizar esta acción"
        case .notFound:
            return "Recurso no encontrado"
        case .badRequest(let apiError):
            return apiError?.message ?? "Solicitud incorrecta"
        case .serverError(let apiError):
            return apiError?.message ?? "Error del servidor. Intenta más tarde"
        case .decodingError:
            return "Error procesando la respuesta del servidor"
        case .noInternetConnection:
            return "Sin conexión a internet. Verifica tu conexión"
        case .timeout:
            return "La solicitud tardó demasiado tiempo. Intenta nuevamente"
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Demasiadas solicitudes. Intenta en \(Int(retryAfter)) segundos"
            } else {
                return "Demasiadas solicitudes. Espera un momento e intenta nuevamente"
            }
        case .maintenance:
            return "Servicio en mantenimiento. Intenta más tarde"
        case .unknown(let error):
            return "Error inesperado: \(error.localizedDescription)"
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
    
    // MARK: - Icon for UI Display
    var iconName: String {
        switch self {
        case .noInternetConnection:
            return "wifi.slash"
        case .timeout:
            return "clock.arrow.circlepath"
        case .unauthorized:
            return "person.crop.circle.badge.xmark"
        case .forbidden:
            return "lock.fill"
        case .notFound:
            return "questionmark.circle"
        case .serverError, .maintenance:
            return "server.rack"
        case .rateLimited:
            return "speedometer"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    // MARK: - Error Category for Analytics
    var category: String {
        switch self {
        case .invalidURL, .invalidResponse, .decodingError:
            return "client_error"
        case .unauthorized, .forbidden:
            return "auth_error"
        case .notFound, .badRequest:
            return "request_error"
        case .serverError, .maintenance:
            return "server_error"
        case .noInternetConnection, .timeout:
            return "network_error"
        case .rateLimited:
            return "rate_limit_error"
        case .unknown:
            return "unknown_error"
        }
    }
    
    // MARK: - Convert Any Error to NetworkError
    static func from(_ error: Error) -> NetworkError {
        // If it's already a NetworkError, return as-is
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        // Convert URLError to NetworkError with enhanced device-specific messages
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .timedOut:
                return .timeout
            case .cannotFindHost, .cannotConnectToHost:
                // 🔧 FIX: Better error handling for localhost connection issues on physical devices
                let urlString = urlError.failingURL?.absoluteString ?? ""
                if urlString.contains("localhost") || urlString.contains("127.0.0.1") {
                    #if targetEnvironment(simulator)
                    return .serverError(APIError(
                        message: "No se puede conectar al servidor de desarrollo. Verifica que el servidor esté ejecutándose.",
                        code: "DEV_SERVER_UNAVAILABLE",
                        details: ["Servidor de desarrollo no accesible desde el simulador"]
                    ))
                    #else
                    return .serverError(APIError(
                        message: "Error de configuración: No puedes conectarte a localhost desde un dispositivo físico. La aplicación intentará usar el servidor de staging automáticamente.",
                        code: "LOCALHOST_PHYSICAL_DEVICE",
                        details: [
                            "Los dispositivos físicos no pueden acceder a localhost",
                            "Configura tu IP de desarrollo o usa staging",
                            "Ver logs para instrucciones detalladas"
                        ]
                    ))
                    #endif
                } else {
                    return .serverError(APIError(
                        message: "No se puede conectar al servidor. Verifica tu conexión a internet.",
                        code: "CONNECTION_FAILED",
                        details: ["Error de conectividad de red"]
                    ))
                }
            default:
                return .unknown(urlError)
            }
        }
        
        // Convert DecodingError to NetworkError
        if let decodingError = error as? DecodingError {
            return .decodingError(decodingError)
        }
        
        // Default to unknown
        return .unknown(error)
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
