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
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    func request<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable? = nil
    ) -> AnyPublisher<T, APIError> {
        
        do {
            let request = try buildURLRequest(for: endpoint, body: body)
            
            return session.dataTaskPublisher(for: request)
                .map(\.data)
                .tryMap { [weak self] data in
                    try self?.handleResponse(data: data, responseType: T.self) ?? {
                        throw APIError(
                            message: "Network manager not available",
                            code: "MANAGER_ERROR",
                            timestamp: ISO8601DateFormatter().string(from: Date())
                        )
                    }()
                }
                .mapError { error in
                    if let apiError = error as? APIError {
                        return apiError
                    }
                    
                    if let urlError = error as? URLError {
                        return APIError(
                            message: self.mapURLError(urlError),
                            code: "NETWORK_ERROR",
                            timestamp: ISO8601DateFormatter().string(from: Date())
                        )
                    }
                    
                    return APIError(
                        message: error.localizedDescription,
                        code: "UNKNOWN_ERROR",
                        timestamp: ISO8601DateFormatter().string(from: Date())
                    )
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
            
        } catch {
            return Fail(error: APIError(
                message: "Failed to build request: \(error.localizedDescription)",
                code: "REQUEST_BUILD_ERROR",
                timestamp: ISO8601DateFormatter().string(from: Date())
            ))
            .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Private Methods
    
    private func buildURLRequest(for endpoint: APIEndpoint, body: Codable?) throws -> URLRequest {
        let baseURL = "https://api.figrclub.com" // Cambiar por tu URL base
        
        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            throw APIError(
                message: "Invalid URL",
                code: "INVALID_URL",
                timestamp: ISO8601DateFormatter().string(from: Date())
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
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if available
        if let token = TokenManager.shared.getAccessToken() {
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
                    timestamp: ISO8601DateFormatter().string(from: Date())
                )
            }
        }
        
        return request
    }
    
    private func handleResponse<T: Codable>(data: Data, responseType: T.Type) throws -> T {
        // Log response for debugging
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 API Response: \(jsonString)")
        }
        #endif
        
        // Try to decode as APIResponse<T> first
        if let apiResponse = try? decoder.decode(APIResponse<T>.self, from: data) {
            guard let responseData = apiResponse.data else {
                throw APIError(
                    message: apiResponse.message,
                    code: "EMPTY_DATA",
                    timestamp: apiResponse.timestamp
                )
            }
            return responseData
        }
        
        // Try to decode as APIError
        if let apiError = try? decoder.decode(APIError.self, from: data) {
            throw apiError
        }
        
        // Fallback to direct decoding
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError(
                message: "Failed to decode response: \(error.localizedDescription)",
                code: "DECODING_ERROR",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }
    }
    
    private func mapURLError(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "Sin conexión a internet"
        case .timedOut:
            return "Tiempo de espera agotado"
        case .cannotFindHost:
            return "No se puede encontrar el servidor"
        case .cannotConnectToHost:
            return "No se puede conectar al servidor"
        case .networkConnectionLost:
            return "Conexión perdida"
        case .badURL:
            return "URL inválida"
        default:
            return "Error de red: \(error.localizedDescription)"
        }
    }
}
