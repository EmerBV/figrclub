//
//  URLSessionProvider.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - URL Session Provider Protocol
protocol URLSessionProviderProtocol: Sendable {
    func dataTask(for request: URLRequest) async throws -> (Data, URLResponse)
    func createURLRequest(for endpoint: APIEndpoint) throws -> URLRequest
}

// MARK: - URL Session Provider Implementation
final class URLSessionProvider: URLSessionProviderProtocol, @unchecked Sendable {
    private let session: URLSession
    private let configuration: APIConfigurationProtocol
    private let logger: NetworkLoggerProtocol
    
    init(configuration: APIConfigurationProtocol, logger: NetworkLoggerProtocol) {
        self.configuration = configuration
        self.logger = logger
        
        self.session = URLSession(configuration: configuration.createURLSessionConfiguration())
        
        Logger.debug("🔧 URLSessionProvider initialized with centralized configuration")
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
    
    func createURLRequest(for endpoint: APIEndpoint) throws -> URLRequest {
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

// MARK: - URLSessionProvider Extensions
extension URLSessionProvider {
    
    /// Create URLRequest with automatic retry policy validation
    func createURLRequestWithRetryValidation(for endpoint: APIEndpoint) throws -> URLRequest {
        let request = try createURLRequest(for: endpoint)
        
        // Validate retry policy settings
        if endpoint.retryPolicy.maxRetries > 0 {
            Logger.debug("🔄 Request configured with retry policy: max \(endpoint.retryPolicy.maxRetries) retries")
        }
        
        return request
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

extension APIEndpoint {
    
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
