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
        self.baseURL = AppConfig.API.baseURL
        self.timeout = AppConfig.API.timeout
        self.allowsCellularAccess = true
        self.waitsForConnectivity = true
        
        // Default headers for all requests
        self.defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "FigrClub iOS \(AppConfig.AppInfo.version)"
        ]
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
    
    static let authRetry = RetryPolicy(
        maxRetries: 1,
        retryDelay: 0.5,
        retryableStatusCodes: [401]
    )
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}
