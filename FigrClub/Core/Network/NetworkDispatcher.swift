//
//  NetworkDispatcher.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol NetworkDispatcherProtocol: Sendable {
    func dispatch<T: Codable>(_ endpoint: Endpoint) async throws -> T
}

final class NetworkDispatcher: NetworkDispatcherProtocol {
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let tokenManager: TokenManager
    
    init(session: URLSession = .shared, tokenManager: TokenManager) {
        self.session = session
        self.tokenManager = tokenManager
        
        self.jsonDecoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        jsonDecoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    func dispatch<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(from: endpoint)
        
        // Log request
        NetworkLogger.logRequest(request)
        
        // Track performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                NetworkLogger.logError(NetworkError.invalidResponse, for: request)
                throw NetworkError.invalidResponse
            }
            
            // Calculate and log performance
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            NetworkLogger.logPerformance(
                url: request.url?.absoluteString ?? "Unknown",
                duration: duration,
                dataSize: data.count
            )
            
            // Log response
            NetworkLogger.logResponse(httpResponse, data: data)
            
            let validatedData = try validateResponse(data: data, response: httpResponse)
            let decodedResponse = try jsonDecoder.decode(T.self, from: validatedData)
            
            return decodedResponse
        } catch {
            // Log error with request context
            NetworkLogger.logError(error, for: request)
            
            if let networkError = error as? NetworkError {
                throw networkError
            } else if let decodingError = error as? DecodingError {
                throw NetworkError.decodingError(decodingError)
            } else {
                throw NetworkError.unknown(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(from endpoint: Endpoint) async throws -> URLRequest {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = AppConfig.API.timeout
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if needed
        if endpoint.requiresAuth {
            if let token = await tokenManager.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw NetworkError.unauthorized
            }
        }
        
        // Add custom headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    private func validateResponse(data: Data, response: HTTPURLResponse) throws -> Data {
        switch response.statusCode {
        case 200...299:
            return data
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400...499:
            let apiError = try? jsonDecoder.decode(APIError.self, from: data)
            throw NetworkError.badRequest(apiError)
        case 500...599:
            let apiError = try? jsonDecoder.decode(APIError.self, from: data)
            throw NetworkError.serverError(apiError)
        default:
            throw NetworkError.unknown(NSError(domain: "HTTPError", code: response.statusCode, userInfo: nil))
        }
    }
}

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
        case .decodingError:
            return "Error al procesar la respuesta"
        case .noInternetConnection:
            return "Sin conexión a internet"
        case .timeout:
            return "Tiempo de espera agotado"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
