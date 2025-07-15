//
//  APIEndpoint.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

// MARK: - Enhanced Endpoint Protocol
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any]? { get }
    var queryParameters: [String: Any]? { get }
    var requiresAuth: Bool { get }
    var isRefreshTokenEndpoint: Bool { get }
    var retryPolicy: RetryPolicy { get }
    var cachePolicy: CachePolicy { get }
    var cacheMaxAge: TimeInterval { get }
}

extension APIEndpoint {
    var headers: [String: String] { [:] }
    var body: [String: Any]? { nil }
    var queryParameters: [String: Any]? { nil }
    var requiresAuth: Bool { true }
    var isRefreshTokenEndpoint: Bool { false }
    var retryPolicy: RetryPolicy { .default }
    var cachePolicy: CachePolicy { .cacheFirst }
    var cacheMaxAge: TimeInterval { 300 } // 5 minutes default
}

// MARK: - Helper Extension
extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
}


