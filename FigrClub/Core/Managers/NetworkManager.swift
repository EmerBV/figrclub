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
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
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
    ) -> AnyPublisher<T, APIError> {
        
        return Future<T, APIError> { promise in
            Task {
                do {
                    let result: T = try await self.performRequest(endpoint: endpoint, body: body)
                    promise(.success(result))
                } catch {
                    if let apiError = error as? APIError {
                        promise(.failure(apiError))
                    } else {
                        let apiError = APIError(
                            message: "Request failed: \(error.localizedDescription)",
                            code: "REQUEST_FAILED"
                        )
                        promise(.failure(apiError))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
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
                code: "INVALID_RESPONSE"
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
                code: "INVALID_URL"
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
                code: "URL_CONSTRUCTION_ERROR"
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
                    code: "ENCODING_ERROR"
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
                code: errorResponse.code ?? "API_ERROR"
            )
        }
        
        // Fallback error
        throw APIError(
            message: HTTPURLResponse.localizedString(forStatusCode: statusCode),
            code: "HTTP_\(statusCode)"
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
                        code: "EMPTY_DATA"
                    )
                }
                return responseData
            } catch {
                Logger.shared.error("Failed to decode response", error: error, category: "network")
                throw APIError(
                    message: "Failed to decode server response",
                    code: "DECODING_ERROR"
                )
            }
        }
    }
}

// MARK: - Bundle Extension for App Version
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

