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
            
            // Log the request
            logRequest(request, endpoint: endpoint)
            
            return session.dataTaskPublisher(for: request)
                .tryMap { [weak self] data, response in
                    // Log the response
                    self?.logResponse(data: data, response: response, endpoint: endpoint)
                    
                    // Check HTTP status
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode >= 400 {
                            // Try to decode error response
                            if let errorResponse = try? self?.decoder.decode(APIErrorResponse.self, from: data) {
                                throw APIError(
                                    message: errorResponse.message,
                                    code: errorResponse.code ?? "HTTP_\(httpResponse.statusCode)",
                                    timestamp: errorResponse.timestamp
                                )
                            } else {
                                throw APIError(
                                    message: "HTTP Error \(httpResponse.statusCode)",
                                    code: "HTTP_\(httpResponse.statusCode)",
                                    timestamp: ISO8601DateFormatter().string(from: Date())
                                )
                            }
                        }
                    }
                    
                    return try self?.handleResponse(data: data, responseType: T.self) ?? {
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
        let baseURL = AppConfig.API.baseURL
        
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
                    timestamp: ISO8601DateFormatter().string(from: Date())
                )
            }
        }
        
        return request
    }
    
    private func handleResponse<T: Codable>(data: Data, responseType: T.Type) throws -> T {
        // Log raw response for debugging
#if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw API Response for \(T.self): \(jsonString)")
            
            // Usar el DebugHelper para inspeccionar la estructura
            DebugHelper.inspectJSONStructure(jsonString)
            
            // Intentar validar contra diferentes modelos
            print("🧪 Testing decode strategies:")
            DebugHelper.validateJSON(jsonString, as: APIResponse<T>.self)
            DebugHelper.validateJSON(jsonString, as: T.self)
        }
#endif
        
        // Strategy 1: Try to decode as wrapped APIResponse<T>
        do {
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
            guard let responseData = apiResponse.data else {
                throw APIError(
                    message: apiResponse.message,
                    code: "EMPTY_DATA",
                    timestamp: String(apiResponse.timestamp)
                )
            }
            Logger.shared.debug("✅ Successfully decoded as wrapped APIResponse", category: "network")
            return responseData
        } catch {
            Logger.shared.debug("❌ Failed to decode as APIResponse<T>: \(error)", category: "network")
        }
        
        // Strategy 2: Try to decode directly as T
        do {
            let directResponse = try decoder.decode(T.self, from: data)
            Logger.shared.debug("✅ Successfully decoded directly as \(T.self)", category: "network")
            return directResponse
        } catch {
            Logger.shared.debug("❌ Failed to decode directly as \(T.self): \(error)", category: "network")
        }
        
        // Strategy 3: Try to decode as error response
        if let apiError = try? decoder.decode(APIError.self, from: data) {
            throw apiError
        }
        
        // Strategy 4: Try to decode as APIErrorResponse
        if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
            throw APIError(
                message: errorResponse.message,
                code: errorResponse.code ?? "API_ERROR",
                timestamp: errorResponse.timestamp
            )
        }
        
        // If all strategies fail, throw a detailed error
        throw APIError(
            message: "Failed to decode response as \(T.self). Raw data length: \(data.count) bytes",
            code: "DECODING_ERROR",
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func logRequest(_ request: URLRequest, endpoint: APIEndpoint) {
#if DEBUG
        print("🚀 API Request: \(endpoint.method.rawValue) \(request.url?.absoluteString ?? "unknown")")
        if let headers = request.allHTTPHeaderFields {
            print("📋 Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
#endif
        
        Logger.shared.logNetworkRequest(
            method: endpoint.method.rawValue,
            url: request.url?.absoluteString ?? "unknown"
        )
    }
    
    private func logResponse(data: Data, response: URLResponse, endpoint: APIEndpoint) {
#if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response Status: \(httpResponse.statusCode)")
            print("📋 Response Headers: \(httpResponse.allHeaderFields)")
        }
#endif
        
        if let httpResponse = response as? HTTPURLResponse {
            Logger.shared.logNetworkRequest(
                method: endpoint.method.rawValue,
                url: httpResponse.url?.absoluteString ?? "unknown",
                statusCode: httpResponse.statusCode
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
