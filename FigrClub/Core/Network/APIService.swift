//
//  APIService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - API Service Protocol
protocol APIServiceProtocol {
    func request<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable?
    ) -> AnyPublisher<T, APIError>
}

// MARK: - API Service Implementation
final class APIService: APIServiceProtocol {
    static let shared = APIService()
    
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    func request<T: Codable>(
        endpoint: APIEndpoint,
        body: Codable? = nil
    ) -> AnyPublisher<T, APIError> {
        
#if DEBUG
        print("🚀 API Request: \(endpoint.method.rawValue) \(endpoint.path)")
        if let body = body {
            print("📤 Request Body: \(body)")
        }
#endif
        
        // Validar endpoint antes de hacer la petición
        do {
            try endpoint.validateEndpoint()
        } catch {
            return Fail(error: error as? APIError ?? APIError(
                message: "Endpoint validation failed",
                code: "VALIDATION_ERROR"
            ))
            .eraseToAnyPublisher()
        }
        
        return networkManager.request(endpoint: endpoint, body: body)
    }
}

// MARK: - Convenience Extensions
extension APIService {
    
    // MARK: - Authentication
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        let loginRequest = LoginRequest(email: email, password: password)
        return request(endpoint: .login, body: loginRequest)
    }
    
    
}

