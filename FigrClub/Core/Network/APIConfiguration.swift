//
//  APIConfiguration.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import Foundation

// MARK: - API Configuration Protocol
protocol APIConfigurationProtocol: Sendable {
    var baseURL: String { get }
    var timeout: TimeInterval { get }
    var defaultHeaders: [String: String] { get }
    var allowsCellularAccess: Bool { get }
    var waitsForConnectivity: Bool { get }
    
    func createURLSessionConfiguration() -> URLSessionConfiguration
}

// MARK: - API Configuration Implementation
final class APIConfiguration: APIConfigurationProtocol {
    let baseURL: String
    let timeout: TimeInterval
    let defaultHeaders: [String: String]
    let allowsCellularAccess: Bool
    let waitsForConnectivity: Bool
    
    init() {
        // Use the advanced AppConfig
        let config = AppConfig.shared
        
        self.baseURL = config.apiBaseURL
        self.timeout = config.apiTimeout
        self.allowsCellularAccess = true
        self.waitsForConnectivity = true
        
        // Get default headers from AppConfig (includes User-Agent, version info, etc.)
        self.defaultHeaders = config.getDefaultHeaders()
        
        Logger.debug("🔧 APIConfiguration initialized:")
        Logger.debug("  🌐 Base URL: \(baseURL)")
        Logger.debug("  ⏱️ Timeout: \(timeout)s")
        Logger.debug("  📱 Cellular Access: \(allowsCellularAccess)")
        Logger.debug("  🔗 Wait for Connectivity: \(waitsForConnectivity)")
        Logger.debug("  📋 Headers: \(defaultHeaders.keys.joined(separator: ", "))")
    }
    
    // ✅ CENTRALIZED: Single source of truth for URLSession configuration
    func createURLSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        
        // Timeout settings
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        
        // Network settings
        config.allowsCellularAccess = allowsCellularAccess
        config.waitsForConnectivity = waitsForConnectivity
        
        // Security settings
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        Logger.debug("🔧 URLSessionConfiguration created with centralized settings")
        return config
    }
    
    /// Get configuration summary for debugging
    func getConfigurationSummary() -> String {
        return """
        APIConfiguration Summary:
        • Base URL: \(baseURL)
        • Timeout: \(timeout)s
        • Headers: \(defaultHeaders.count) items
        • Cellular: \(allowsCellularAccess ? "Enabled" : "Disabled")
        • Wait Connectivity: \(waitsForConnectivity ? "Enabled" : "Disabled")
        """
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}

// MARK: - Retry Policy
struct RetryPolicy {
    let maxRetries: Int
    let retryDelay: TimeInterval
    let retryableStatusCodes: Set<Int>
    
    static let `default` = RetryPolicy(
        maxRetries: 3,
        retryDelay: 1.0,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )
    
    static let noRetry = RetryPolicy(
        maxRetries: 0,
        retryDelay: 0,
        retryableStatusCodes: []
    )
    
    static let aggressive = RetryPolicy(
        maxRetries: 5,
        retryDelay: 0.5,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )
}

// MARK: - Configuration Factory Methods
extension APIConfiguration {
    
    /// Create configuration for specific environment
    static func forEnvironment(_ environment: AppEnvironment) -> APIConfiguration {
        let currentEnv = AppConfig.shared.environment
        AppConfig.shared.setEnvironment(environment)
        let config = APIConfiguration()
        AppConfig.shared.setEnvironment(currentEnv) // Restore original
        return config
    }
    
}

// MARK: - Validation
extension APIConfiguration {
    
    /// Validate configuration settings
    func validate() -> Bool {
        guard !baseURL.isEmpty else {
            Logger.error("❌ APIConfiguration: Base URL is empty")
            return false
        }
        
        guard URL(string: baseURL) != nil else {
            Logger.error("❌ APIConfiguration: Invalid base URL: \(baseURL)")
            return false
        }
        
        guard timeout > 0 else {
            Logger.error("❌ APIConfiguration: Invalid timeout: \(timeout)")
            return false
        }
        
        Logger.debug("✅ APIConfiguration: Validation passed")
        return true
    }
}

