//
//  APIService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

/*
protocol APIServiceProtocol: Sendable {
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T
    func requestData(_ endpoint: Endpoint) async throws -> Data
    
    // Método dispatch para compatibilidad hacia atrás
    func dispatch<T: Codable>(_ endpoint: Endpoint) async throws -> T
}

// MARK: - Unified Network Service Implementation
final class APIService: APIServiceProtocol, NetworkDispatcherProtocol, @unchecked Sendable {
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let tokenManager: TokenManager
    
    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        
        // Configure URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.API.timeout
        config.timeoutIntervalForResource = AppConfig.API.timeout * 2
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        self.session = URLSession(configuration: config)
        
        // Configure JSON Decoder
        self.jsonDecoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        jsonDecoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    // MARK: - Public Methods
    
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint)
        
        do {
            let result = try jsonDecoder.decode(T.self, from: data)
            return result
        } catch {
            Logger.error("Decoding error for \(T.self): \(error)")
            throw NetworkError.decodingError(error as? DecodingError ?? DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown decoding error")))
        }
    }
    
    // Método dispatch para compatibilidad hacia atrás
    func dispatch<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        return try await request(endpoint)
    }
    
    func requestData(_ endpoint: Endpoint) async throws -> Data {
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
            
            return try validateResponse(data: data, response: httpResponse)
            
        } catch {
            // Log error with request context
            NetworkLogger.logError(error, for: request)
            
            if let networkError = error as? NetworkError {
                throw networkError
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
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("FigrClub iOS", forHTTPHeaderField: "User-Agent")
        
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

