//
//  APIService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

protocol APIServiceProtocol: Sendable {
    func request<T: Codable>(_ endpoint: APIEndpoint, body: Data?) async throws -> T
    func request<T: Codable>(_ endpoint: APIEndpoint, parameters: [String: Any]?) async throws -> T
}

final class APIService: APIServiceProtocol, Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.API.timeout
        config.timeoutIntervalForResource = AppConfig.API.timeout
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        // Configure date decoding strategy
        let dateFormatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to timestamp
            if let timestamp = Double(dateString) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
    }
    
    func request<T: Codable>(_ endpoint: APIEndpoint, body: Data? = nil) async throws -> T {
        guard let url = endpoint.url() else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.addCommonHeaders()
        
        if let body = body {
            request.httpBody = body
        }
        
        // Add auth token if required
        if endpoint.requiresAuthentication {
            if let token = await getAuthToken() {
                request.addAuthHeader(token)
            } else {
                throw APIError.authenticationFailed
            }
        }
        
        Logger.debug("API Request: \(endpoint.method.rawValue) \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            Logger.debug("API Response: \(httpResponse.statusCode)")
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let result = try decoder.decode(T.self, from: data)
                    return result
                } catch {
                    Logger.error("Decoding error: \(error)")
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.authenticationFailed
            case 404:
                throw APIError.userNotFound
            case 400...499:
                // Try to decode error response
                if let errorData = try? decoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.networkError(NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorData.message]))
                }
                throw APIError.serverError(httpResponse.statusCode)
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.unknown
            }
        } catch {
            if error is APIError {
                throw error
            }
            Logger.error("Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    func request<T: Codable>(_ endpoint: APIEndpoint, parameters: [String: Any]?) async throws -> T {
        var body: Data?
        
        if let parameters = parameters {
            do {
                body = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                throw APIError.networkError(error)
            }
        }
        
        return try await request(endpoint, body: body)
    }
    
    private func getAuthToken() async -> String? {
        // Get token from TokenManager
        return await TokenManager.shared.getToken()
    }
}

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let message: String
    let code: String?
}

// MARK: - URLRequest Extensions
extension URLRequest {
    mutating func addCommonHeaders() {
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        setValue("application/json", forHTTPHeaderField: "Accept")
        setValue("FigrClub/\(AppConfig.AppInfo.version)", forHTTPHeaderField: "User-Agent")
        setValue(Locale.current.language.languageCode?.identifier, forHTTPHeaderField: "Accept-Language")
    }
    
    mutating func addAuthHeader(_ token: String) {
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
