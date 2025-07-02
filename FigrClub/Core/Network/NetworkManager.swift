//
//  NetworkManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - Network Manager
final class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let errorHandler: ErrorHandler
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.errorHandler = DefaultErrorHandler()
        
        setupDecoder()
    }
    
    private func setupDecoder() {
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Main Request Method
    func request<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable? = nil
    ) -> AsyncThrowingStream<T, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let result: T = try await performRequest(endpoint: endpoint, body: body)
                    continuation.yield(result)
                    continuation.finish()
                } catch {
                    let strategy = errorHandler.handle(error)
                    
                    switch strategy {
                    case .retry(let maxAttempts, let delay):
                        await handleRetry(
                            endpoint: endpoint,
                            body: body,
                            maxAttempts: maxAttempts,
                            delay: delay,
                            continuation: continuation
                        )
                    case .refreshTokenAndRetry:
                        await handleTokenRefreshAndRetry(
                            endpoint: endpoint,
                            body: body,
                            continuation: continuation
                        )
                    case .showError, .silent, .logout:
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Core Request Logic
    private func performRequest<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable?
    ) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, body: body)
        
        Logger.shared.debug("🚀 Making request: \(endpoint.method.rawValue) \(endpoint.path)", category: "network")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(
                message: "Invalid response type",
                code: "INVALID_RESPONSE",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                statusCode: nil,
                details: nil
            )
        }
        
        Logger.shared.debug("📥 Response: \(httpResponse.statusCode) for \(endpoint.path)", category: "network")
        
        // Handle different status codes
        try validateResponse(httpResponse, data: data)
        
        return try decodeResponse(data: data, responseType: T.self)
    }
    
    // MARK: - Request Building
    private func buildRequest(endpoint: APIEndpoint, body: Codable?) throws -> URLRequest {
        let baseURL = AppConfig.API.baseURL
        
        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            throw APIError(
                message: "Invalid URL",
                code: "INVALID_URL",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                statusCode: nil,
                details: nil
            )
        }
        
        // Add query parameters for GET requests
        if let queryParameters = endpoint.queryParameters {
            urlComponents.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }
        
        guard let url = urlComponents.url else {
            throw APIError(
                message: "Failed to construct URL",
                code: "URL_CONSTRUCTION_ERROR",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                statusCode: nil,
                details: nil
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue(Bundle.main.appVersion, forHTTPHeaderField: "X-App-Version")
        
        // Add auth token if required and available
        if endpoint.requiresAuthentication, let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body for non-GET requests
        if let body = body, endpoint.method != .get {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError(
                    message: "Failed to encode request body",
                    code: "ENCODING_ERROR",
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    statusCode: nil,
                    details: ["encoding_error": error.localizedDescription]
                )
            }
        }
        
        return request
    }
    
    // MARK: - Response Validation
    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        let statusCode = response.statusCode
        
        // Success status codes
        if 200...299 ~= statusCode {
            return
        }
        
        // Try to decode error response
        if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
            throw APIError(
                message: errorResponse.message,
                code: errorResponse.code ?? "API_ERROR",
                timestamp: errorResponse.timestamp,
                statusCode: statusCode,
                details: nil
            )
        }
        
        // Fallback error
        throw APIError(
            message: HTTPURLResponse.localizedString(forStatusCode: statusCode),
            code: "HTTP_\(statusCode)",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            statusCode: statusCode,
            details: nil
        )
    }
    
    // MARK: - Response Decoding
    private func decodeResponse<T: Codable>(data: Data, responseType: T.Type) throws -> T {
        do {
            // Try direct decoding first
            return try decoder.decode(T.self, from: data)
        } catch {
            // Try as wrapped API response
            do {
                let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
                guard let responseData = apiResponse.data else {
                    throw APIError(
                        message: "No data in API response",
                        code: "EMPTY_DATA",
                        timestamp: String(apiResponse.timestamp),
                        statusCode: apiResponse.status,
                        details: nil
                    )
                }
                return responseData
            } catch {
                Logger.shared.error("Failed to decode response", error: error, category: "network")
                throw APIError(
                    message: "Failed to decode server response",
                    code: "DECODING_ERROR",
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    statusCode: nil,
                    details: ["decoding_error": error.localizedDescription]
                )
            }
        }
    }
    
    // MARK: - Retry Logic
    private func handleRetry<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable?,
        maxAttempts: Int,
        delay: TimeInterval,
        continuation: AsyncThrowingStream<T, Error>.Continuation
    ) async {
        var attempts = 0
        
        while attempts < maxAttempts {
            attempts += 1
            
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                let result: T = try await performRequest(endpoint: endpoint, body: body)
                continuation.yield(result)
                continuation.finish()
                return
            } catch {
                if attempts == maxAttempts {
                    continuation.finish(throwing: error)
                    return
                }
                Logger.shared.warning("Retry attempt \(attempts)/\(maxAttempts) failed", category: "network")
            }
        }
    }
    
    // MARK: - Token Refresh and Retry
    private func handleTokenRefreshAndRetry<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable?,
        continuation: AsyncThrowingStream<T, Error>.Continuation
    ) async {
        do {
            // Attempt token refresh
            let refreshResult = await TokenManager.shared.refreshTokenIfNeeded()
            
            switch refreshResult {
            case .success:
                // Retry the original request
                let result: T = try await performRequest(endpoint: endpoint, body: body)
                continuation.yield(result)
                continuation.finish()
            case .failure(let error):
                continuation.finish(throwing: error)
            }
        } catch {
            continuation.finish(throwing: error)
        }
    }
}

// MARK: - Bundle Extension for App Version
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

