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
    
    // MARK: - Convenience Initializers
    init(message: String, code: String = "UNKNOWN_ERROR", statusCode: Int? = nil) {
        self.message = message
        self.code = code
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.statusCode = statusCode
        self.details = nil
    }
    
    init(from urlError: URLError) {
        self.message = urlError.localizedDescription
        self.code = "NETWORK_\(urlError.code.rawValue)"
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.statusCode = nil
        self.details = ["url_error_code": "\(urlError.code.rawValue)"]
    }
    
    // MARK: - Static Factory Methods
    static func networkError(_ message: String) -> APIError {
        return APIError(
            message: message,
            code: "NETWORK_ERROR",
            statusCode: nil
        )
    }
    
    static func decodingError(_ message: String) -> APIError {
        return APIError(
            message: message,
            code: "DECODING_ERROR",
            statusCode: nil
        )
    }
    
    static func unauthorized(_ message: String = "No autorizado") -> APIError {
        return APIError(
            message: message,
            code: "UNAUTHORIZED",
            statusCode: 401
        )
    }
    
    static func serverError(_ message: String = "Error del servidor") -> APIError {
        return APIError(
            message: message,
            code: "SERVER_ERROR",
            statusCode: 500
        )
    }
}

// MARK: - API Error Response (for server responses)
struct APIErrorResponse: Codable {
    let message: String
    let code: String?
    let timestamp: String
    let details: [String: String]?
    
    func toAPIError(statusCode: Int) -> APIError {
        return APIError(
            message: message,
            code: code ?? "API_ERROR",
            statusCode: statusCode
        )
    }
}

// MARK: - HTTP Status Code Extensions
extension APIError {
    var httpStatusDescription: String {
        guard let statusCode = statusCode else {
            return "Sin código de estado"
        }
        
        switch statusCode {
        case 200...299:
            return "Éxito"
        case 300...399:
            return "Redirección"
        case 400:
            return "Solicitud incorrecta"
        case 401:
            return "No autorizado"
        case 403:
            return "Prohibido"
        case 404:
            return "No encontrado"
        case 422:
            return "Entidad no procesable"
        case 429:
            return "Demasiadas solicitudes"
        case 500:
            return "Error interno del servidor"
        case 502:
            return "Puerta de enlace incorrecta"
        case 503:
            return "Servicio no disponible"
        case 504:
            return "Tiempo de espera de la puerta de enlace"
        default:
            return "Error HTTP \(statusCode)"
        }
    }
    
    var shouldRetry: Bool {
        guard let statusCode = statusCode else {
            return true // Network errors should be retried
        }
        
        switch statusCode {
        case 408, 429, 500, 502, 503, 504:
            return true
        default:
            return false
        }
    }
    
    var retryDelay: TimeInterval {
        guard let statusCode = statusCode else {
            return 2.0
        }
        
        switch statusCode {
        case 429: // Rate limiting
            return 60.0
        case 500...599: // Server errors
            return 5.0
        default:
            return 2.0
        }
    }
}

// MARK: - Error Mapping
extension APIError {
    static func from(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        
        if let urlError = error as? URLError {
            return APIError(from: urlError)
        }
        
        if let decodingError = error as? DecodingError {
            return APIError.decodingError("Error al procesar la respuesta del servidor")
        }
        
        return APIError(
            message: error.localizedDescription,
            code: "UNKNOWN_ERROR",
            statusCode: nil
        )
    }
}

// MARK: - Use Case Error
enum UseCaseError: Error {
    case invalidInput(String)
    case unauthorized
    case notFound
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .unauthorized:
            return "No tienes autorización para realizar esta acción"
        case .notFound:
            return "El recurso solicitado no fue encontrado"
        case .networkError:
            return "Error de conexión. Verifica tu internet"
        case .unknownError:
            return "Ha ocurrido un error inesperado"
        }
    }
    
    static func from(_ apiError: APIError) -> UseCaseError {
        if apiError.isAuthenticationError {
            return .unauthorized
        }
        
        if apiError.statusCode == 404 {
            return .notFound
        }
        
        if apiError.isNetworkError {
            return .networkError
        }
        
        if let statusCode = apiError.statusCode, (statusCode == 400 || statusCode == 422) {
            return .invalidInput(apiError.message)
        }
        
        return .unknownError
    }
}

// MARK: - Error Recovery Context
struct ErrorRecoveryContext {
    let error: APIError
    let operation: String
    let attemptNumber: Int
    let maxAttempts: Int
    
    var shouldRetry: Bool {
        return attemptNumber < maxAttempts && error.shouldRetry
    }
    
    var nextRetryDelay: TimeInterval {
        // Exponential backoff with jitter
        let baseDelay = error.retryDelay
        let exponentialDelay = baseDelay * pow(2.0, Double(attemptNumber - 1))
        let jitter = Double.random(in: 0.5...1.5)
        return exponentialDelay * jitter
    }
}

// MARK: - Detailed Error Information
extension APIError {
    var debugDescription: String {
        var description = """
        APIError:
        - Message: \(message)
        - Code: \(code)
        - Status Code: \(statusCode?.description ?? "N/A")
        - Timestamp: \(timestamp)
        """
        
        if let details = details, !details.isEmpty {
            description += "\n- Details:"
            for (key, value) in details {
                description += "\n  - \(key): \(value)"
            }
        }
        
        return description
    }
    
    var userFriendlyMessage: String {
        // Return a user-friendly version of the error message
        switch code {
        case "VALIDATION_ERROR":
            return "Por favor, revisa los datos ingresados"
        case "NETWORK_ERROR":
            return "Error de conexión. Verifica tu internet"
        case "UNAUTHORIZED":
            return "Tu sesión ha expirado. Inicia sesión nuevamente"
        case "SERVER_ERROR":
            return "Error del servidor. Inténtalo más tarde"
        default:
            return message
        }
    }
}

// MARK: - Error Analytics
extension APIError {
    var analyticsData: [String: Any] {
        var data: [String: Any] = [
            "error_message": message,
            "error_code": code,
            "timestamp": timestamp
        ]
        
        if let statusCode = statusCode {
            data["status_code"] = statusCode
        }
        
        if let details = details {
            data["details"] = details
        }
        
        return data
    }
}

