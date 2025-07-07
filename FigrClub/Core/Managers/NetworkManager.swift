//
//  NetworkManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - Network Manager
protocol NetworkManagerProtocol {
    func performRequest<T: Codable>(_ request: URLRequest) async throws -> T
}

final class NetworkManager: NetworkManagerProtocol {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }
    
    func performRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        // Implementación temporal
        throw APIError.notImplemented
    }
}

// MARK: - Bundle Extension for App Version
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

