//
//  NetworkDispatcher.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

/*
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
 */

// MARK: - Network Dispatcher Protocol
protocol NetworkDispatcherProtocol: Sendable {
    func dispatch<T: Codable>(_ endpoint: Endpoint) async throws -> T
    func dispatchData(_ endpoint: Endpoint) async throws -> Data
}

// MARK: - Network Dispatcher Implementation
final class NetworkDispatcher: NetworkDispatcherProtocol, @unchecked Sendable {
    
    // MARK: - Dependencies
    private let sessionProvider: URLSessionProviderProtocol
    private let tokenManager: TokenManager
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Token Refresh Control
    private let refreshQueue = DispatchQueue(label: "com.figrclub.token-refresh", qos: .userInitiated)
    private var isRefreshingToken = false
    private var pendingRequests: [(CheckedContinuation<String, Error>)] = []
    
    // MARK: - Initialization
    init(sessionProvider: URLSessionProviderProtocol, tokenManager: TokenManager) {
        self.sessionProvider = sessionProvider
        self.tokenManager = tokenManager
        
        // Configure JSON Decoder with modern settings
        self.jsonDecoder = JSONDecoder()
        
        // Enhanced date decoding strategy
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // Try different date formats
            if let dateString = try? container.decode(String.self) {
                // ISO8601 with fractional seconds
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
                
                // Custom format
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Unix timestamp as string
                if let timestamp = Double(dateString) {
                    return Date(timeIntervalSince1970: timestamp)
                }
            }
            
            // Unix timestamp as number
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }
    }
    
    // MARK: - Public Methods
    
    func dispatch<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await dispatchData(endpoint)
        
        do {
            let result = try jsonDecoder.decode(T.self, from: data)
            return result
        } catch let decodingError as DecodingError {
            Logger.error("Decoding error for \(T.self): \(decodingError)")
            throw NetworkError.decodingError(decodingError)
        } catch {
            Logger.error("Unknown decoding error for \(T.self): \(error)")
            throw NetworkError.unknown(error)
        }
    }
    
    func dispatchData(_ endpoint: Endpoint) async throws -> Data {
        if endpoint.requiresAuth && !endpoint.isRefreshTokenEndpoint {
            return try await executeAuthenticatedRequest(endpoint)
        } else {
            return try await executeRequest(endpoint)
        }
    }
    
    // MARK: - Private Methods
    
    private func executeAuthenticatedRequest(_ endpoint: Endpoint) async throws -> Data {
        // First, try with current token
        do {
            return try await executeRequestWithCurrentToken(endpoint)
        } catch NetworkError.unauthorized {
            // Token might be expired, try to refresh
            let newToken = try await refreshTokenIfNeeded()
            
            // Retry with new token
            return try await executeRequestWithToken(endpoint, token: newToken)
        } catch {
            throw error
        }
    }
    
    private func executeRequestWithCurrentToken(_ endpoint: Endpoint) async throws -> Data {
        guard let token = await tokenManager.getToken() else {
            throw NetworkError.unauthorized
        }
        
        return try await executeRequestWithToken(endpoint, token: token)
    }
    
    private func executeRequestWithToken(_ endpoint: Endpoint, token: String) async throws -> Data {
        var request = try sessionProvider.createURLRequest(for: endpoint)
        
        // Add authorization header
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return try await executeRequestWithRetry(request, policy: endpoint.retryPolicy)
    }
    
    private func executeRequest(_ endpoint: Endpoint) async throws -> Data {
        let request = try sessionProvider.createURLRequest(for: endpoint)
        return try await executeRequestWithRetry(request, policy: endpoint.retryPolicy)
    }
    
    private func executeRequestWithRetry(_ request: URLRequest, policy: RetryPolicy) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0...policy.maxRetries {
            do {
                let (data, response) = try await sessionProvider.dataTask(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // Check if we should retry based on status code
                if attempt < policy.maxRetries && policy.retryableStatusCodes.contains(httpResponse.statusCode) {
                    Logger.warning("Request failed with status \(httpResponse.statusCode), retrying in \(policy.retryDelay)s")
                    try await Task.sleep(for: .seconds(policy.retryDelay))
                    continue
                }
                
                return try validateResponse(data: data, response: httpResponse)
                
            } catch let error as NetworkError {
                lastError = error
                
                // Don't retry on certain errors
                switch error {
                case .unauthorized, .forbidden, .notFound:
                    throw error
                default:
                    if attempt < policy.maxRetries {
                        Logger.warning("Request failed, retrying in \(policy.retryDelay)s: \(error)")
                        try await Task.sleep(for: .seconds(policy.retryDelay))
                        continue
                    }
                }
            } catch {
                lastError = error
                if attempt < policy.maxRetries {
                    Logger.warning("Request failed, retrying in \(policy.retryDelay)s: \(error)")
                    try await Task.sleep(for: .seconds(policy.retryDelay))
                    continue
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown(NSError(domain: "UnknownError", code: -1))
    }
    
    // MARK: - Token Refresh Logic
    
    private func refreshTokenIfNeeded() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            refreshQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NetworkError.unknown(NSError(domain: "SelfNil", code: -1)))
                    return
                }
                
                // If already refreshing, queue this request
                if self.isRefreshingToken {
                    self.pendingRequests.append(continuation)
                    return
                }
                
                // Start refresh process
                self.isRefreshingToken = true
                
                Task {
                    do {
                        let newToken = try await self.performTokenRefresh()
                        
                        await MainActor.run {
                            // Resume all pending requests
                            self.refreshQueue.async {
                                for pendingContinuation in self.pendingRequests {
                                    pendingContinuation.resume(returning: newToken)
                                }
                                self.pendingRequests.removeAll()
                                self.isRefreshingToken = false
                            }
                        }
                        
                        continuation.resume(returning: newToken)
                        
                    } catch {
                        await MainActor.run {
                            // Fail all pending requests
                            self.refreshQueue.async {
                                for pendingContinuation in self.pendingRequests {
                                    pendingContinuation.resume(throwing: error)
                                }
                                self.pendingRequests.removeAll()
                                self.isRefreshingToken = false
                            }
                        }
                        
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func performTokenRefresh() async throws -> String {
        // This would call your refresh token endpoint
        // For now, we'll simulate the refresh process
        
        let refreshEndpoint = AuthEndpoints.refreshToken
        let response: AuthResponse = try await dispatch(refreshEndpoint)
        
        // Save new token
        await tokenManager.saveToken(response.data.authToken.token)
        
        return response.data.authToken.token
    }
    
    // MARK: - Response Validation
    
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
