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

// MARK: - Network Logger Protocol
protocol NetworkLoggerProtocol: Sendable {
    func logRequest(_ request: URLRequest)
    func logResponse(_ response: HTTPURLResponse, data: Data)
    func logError(_ error: Error, for request: URLRequest?)
    func logPerformance(url: String, duration: TimeInterval, dataSize: Int)
}

// MARK: - URL Session Provider Protocol
protocol URLSessionProviderProtocol: Sendable {
    func dataTask(for request: URLRequest) async throws -> (Data, URLResponse)
    func createURLRequest(for endpoint: Endpoint) throws -> URLRequest
}

// MARK: - URL Session Provider Implementation
final class URLSessionProvider: URLSessionProviderProtocol, @unchecked Sendable {
    private let session: URLSession
    private let configuration: APIConfigurationProtocol
    private let logger: NetworkLoggerProtocol
    
    init(configuration: APIConfigurationProtocol, logger: NetworkLoggerProtocol) {
        self.configuration = configuration
        self.logger = logger
        
        // Configure URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout
        config.timeoutIntervalForResource = configuration.timeout * 2
        config.allowsCellularAccess = configuration.allowsCellularAccess
        config.waitsForConnectivity = configuration.waitsForConnectivity
        
        // Security configurations
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: config)
        
        Logger.debug("🔧 URLSessionProvider initialized with:")
        Logger.debug("  ⏱️ Request Timeout: \(config.timeoutIntervalForRequest)s")
        Logger.debug("  📱 Cellular Access: \(config.allowsCellularAccess)")
        Logger.debug("  🔗 Wait Connectivity: \(config.waitsForConnectivity)")
    }
    
    func dataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        logger.logRequest(request)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.logResponse(httpResponse, data: data)
                logger.logPerformance(
                    url: request.url?.absoluteString ?? "Unknown",
                    duration: duration,
                    dataSize: data.count
                )
            }
            
            return (data, response)
        } catch {
            logger.logError(error, for: request)
            throw error
        }
    }
    
    func createURLRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: configuration.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = configuration.timeout
        
        // Add default headers
        for (key, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add endpoint specific headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add query parameters
        if let queryParameters = endpoint.queryParameters {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            if let urlWithQuery = components?.url {
                request.url = urlWithQuery
            }
        }
        
        // Add body
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    /// Get session configuration summary
    func getSessionSummary() -> String {
        let config = session.configuration
        return """
        URLSession Configuration:
        • Request Timeout: \(config.timeoutIntervalForRequest)s
        • Resource Timeout: \(config.timeoutIntervalForResource)s
        • Cellular Access: \(config.allowsCellularAccess)
        • Wait Connectivity: \(config.waitsForConnectivity)
        • Cookie Policy: \(config.httpCookieAcceptPolicy.rawValue)
        • Cache Policy: \(config.requestCachePolicy.rawValue)
        """
    }
}

// MARK: - Enhanced Endpoint Protocol
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any]? { get }
    var queryParameters: [String: Any]? { get }
    var requiresAuth: Bool { get }
    var isRefreshTokenEndpoint: Bool { get }
    var retryPolicy: RetryPolicy { get }
}

extension Endpoint {
    var headers: [String: String] { [:] }
    var body: [String: Any]? { nil }
    var queryParameters: [String: Any]? { nil }
    var requiresAuth: Bool { true }
    var isRefreshTokenEndpoint: Bool { false }
    var retryPolicy: RetryPolicy { .default }
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
    
    /// Create configuration with custom timeout
    static func withTimeout(_ timeout: TimeInterval) -> APIConfiguration {
        let config = APIConfiguration()
        // Note: This would require making timeout mutable or creating a custom init
        Logger.debug("⏱️ Custom timeout requested: \(timeout)s (using default: \(config.timeout)s)")
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

// MARK: - URLSessionProvider Extensions
extension URLSessionProvider {
    
    /// Create URLRequest with automatic retry policy validation
    func createURLRequestWithRetryValidation(for endpoint: Endpoint) throws -> URLRequest {
        let request = try createURLRequest(for: endpoint)
        
        // Validate retry policy settings
        if endpoint.retryPolicy.maxRetries > 0 {
            Logger.debug("🔄 Request configured with retry policy: max \(endpoint.retryPolicy.maxRetries) retries")
        }
        
        return request
    }
}

// MARK: - Network Error Extensions for Enhanced Endpoint
extension NetworkError {
    
    /// Determine if error is retryable based on endpoint's retry policy
    func isRetryableForEndpoint(_ endpoint: Endpoint) -> Bool {
        switch self {
        case .badRequest, .unauthorized, .forbidden, .notFound:
            return false
        case .serverError, .timeout, .noInternetConnection, .rateLimited:
            return endpoint.retryPolicy.maxRetries > 0
        case .invalidURL, .invalidResponse, .decodingError:
            return false
        case .maintenance:
            return endpoint.retryPolicy.maxRetries > 0
        case .unknown:
            return endpoint.retryPolicy.maxRetries > 0
        }
    }
    
    /// Get the HTTP status code if this is an HTTP error
    var httpStatusCode: Int? {
        switch self {
        case .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .serverError:
            return 500
        case .rateLimited:
            return 429
        default:
            return nil
        }
    }
}

// MARK: - Debug Extensions
#if DEBUG
extension URLSessionProvider {
    
    /// Print detailed session configuration for debugging
    func printSessionConfiguration() {
        let configSummary: String
        if let apiConfig = configuration as? APIConfiguration {
            configSummary = apiConfig.getConfigurationSummary()
        } else {
            configSummary = """
            APIConfiguration Summary:
            • Base URL: \(configuration.baseURL)
            • Timeout: \(configuration.timeout)s
            • Headers: \(configuration.defaultHeaders.count) items
            • Cellular: \(configuration.allowsCellularAccess ? "Enabled" : "Disabled")
            • Wait Connectivity: \(configuration.waitsForConnectivity ? "Enabled" : "Disabled")
            """
        }
        
        print("""
        
        🔧 ===== URLSessionProvider Debug Info =====
        \(getSessionSummary())
        
        📋 Default Headers:
        \(configuration.defaultHeaders.map { "   • \($0.key): \($0.value)" }.joined(separator: "\n"))
        
        🌐 Base Configuration:
        \(configSummary)
        ==========================================
        
        """)
    }
}

extension Endpoint {
    
    /// Get endpoint debug information
    var debugDescription: String {
        return """
        Endpoint Debug Info:
        • Path: \(path)
        • Method: \(method.rawValue)
        • Requires Auth: \(requiresAuth)
        • Refresh Token Endpoint: \(isRefreshTokenEndpoint)
        • Headers: \(headers.count) custom headers
        • Query Parameters: \(queryParameters?.count ?? 0) parameters
        • Body: \(body != nil ? "Present" : "None")
        • Retry Policy: \(retryPolicy.maxRetries) max retries
        """
    }
}
#endif
