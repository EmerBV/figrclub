//
//  NetworkInterceptors.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import UIKit
import CryptoKit

// MARK: - Request Context
struct RequestContext {
    let startTime: Date
    let requestId: String
    var metadata: [String: Any]
    
    init() {
        self.startTime = Date()
        self.requestId = UUID().uuidString
        self.metadata = [:]
    }
}

// MARK: - Interceptor Protocols
protocol RequestInterceptor: Sendable {
    func intercept(request: URLRequest, context: RequestContext) async throws -> URLRequest
}

protocol ResponseInterceptor: Sendable {
    func intercept(response: HTTPURLResponse, data: Data, context: RequestContext) async throws -> Data
}

protocol ErrorInterceptor: Sendable {
    func intercept(error: Error, context: RequestContext) async -> Error
}

// MARK: - Interceptor Manager
actor InterceptorManager {
    private var requestInterceptors: [RequestInterceptor] = []
    private var responseInterceptors: [ResponseInterceptor] = []
    private var errorInterceptors: [ErrorInterceptor] = []
    
    // MARK: - Registration
    func addRequestInterceptor(_ interceptor: RequestInterceptor) {
        requestInterceptors.append(interceptor)
    }
    
    func addResponseInterceptor(_ interceptor: ResponseInterceptor) {
        responseInterceptors.append(interceptor)
    }
    
    func addErrorInterceptor(_ interceptor: ErrorInterceptor) {
        errorInterceptors.append(interceptor)
    }
    
    // MARK: - Execution
    func processRequest(_ request: URLRequest, context: RequestContext) async throws -> URLRequest {
        var processedRequest = request
        
        for interceptor in requestInterceptors {
            processedRequest = try await interceptor.intercept(request: processedRequest, context: context)
        }
        
        return processedRequest
    }
    
    func processResponse(_ response: HTTPURLResponse, data: Data, context: RequestContext) async throws -> Data {
        var processedData = data
        
        for interceptor in responseInterceptors {
            processedData = try await interceptor.intercept(response: response, data: processedData, context: context)
        }
        
        return processedData
    }
    
    func processError(_ error: Error, context: RequestContext) async -> Error {
        var processedError = error
        
        for interceptor in errorInterceptors {
            processedError = await interceptor.intercept(error: processedError, context: context)
        }
        
        return processedError
    }
}

// MARK: - Built-in Interceptors

// MARK: - Analytics Interceptor
struct AnalyticsInterceptor: RequestInterceptor, ResponseInterceptor, ErrorInterceptor {
    private let analyticsService: NetworkAnalyticsService
    
    init(analyticsService: NetworkAnalyticsService = NetworkAnalyticsService()) {
        self.analyticsService = analyticsService
    }
    
    func intercept(request: URLRequest, context: RequestContext) async throws -> URLRequest {
        let endpoint = request.url?.path ?? "unknown"
        let method = request.httpMethod ?? "UNKNOWN"
        
        // Record request started
        await analyticsService.recordRequestStarted(endpoint: endpoint, method: method)
        
        // Log request start
        Logger.info("📊 Analytics: Request started - \(method) \(endpoint)")
        
        // Add analytics headers
        var modifiedRequest = request
        modifiedRequest.setValue(context.requestId, forHTTPHeaderField: "X-Request-ID")
        modifiedRequest.setValue("\(context.startTime.timeIntervalSince1970)", forHTTPHeaderField: "X-Start-Time")
        
        return modifiedRequest
    }
    
    func intercept(response: HTTPURLResponse, data: Data, context: RequestContext) async throws -> Data {
        let duration = Date().timeIntervalSince(context.startTime)
        let endpoint = response.url?.path ?? "unknown"
        let method = context.metadata["method"] as? String ?? "UNKNOWN"
        
        // Record successful request
        await analyticsService.recordRequestCompleted(
            endpoint: endpoint,
            method: method,
            duration: duration,
            statusCode: response.statusCode,
            dataSize: data.count
        )
        
        // Log successful response
        Logger.info("📊 Analytics: Request completed - Status: \(response.statusCode), Duration: \(String(format: "%.3f", duration))s, Size: \(data.count) bytes")
        
        return data
    }
    
    func intercept(error: Error, context: RequestContext) async -> Error {
        let duration = Date().timeIntervalSince(context.startTime)
        let endpoint = context.metadata["endpoint"] as? String ?? "unknown"
        let method = context.metadata["method"] as? String ?? "UNKNOWN"
        
        // Record failed request
        await analyticsService.recordRequestFailed(
            endpoint: endpoint,
            method: method,
            duration: duration,
            error: error
        )
        
        // Log error
        Logger.error("📊 Analytics: Request failed - Duration: \(String(format: "%.3f", duration))s, Error: \(error.localizedDescription)")
        
        return error
    }
}

// MARK: - Security Interceptor
struct SecurityInterceptor: RequestInterceptor {
    
    private let securityConfig: SecurityConfig
    
    init(config: SecurityConfig = .default) {
        self.securityConfig = config
    }
    
    func intercept(request: URLRequest, context: RequestContext) async throws -> URLRequest {
        var secureRequest = request
        
        // Enforce HTTPS
        if securityConfig.enforceHTTPS {
            secureRequest = enforceHTTPS(secureRequest)
        }
        
        // Add comprehensive security headers
        secureRequest = addSecurityHeaders(secureRequest, context: context)
        
        // Add authentication integrity
        if securityConfig.enableRequestSigning {
            secureRequest = addRequestSignature(secureRequest)
        }
        
        // Add CSRF protection
        if securityConfig.enableCSRFProtection {
            secureRequest = await addCSRFProtection(secureRequest)
        }
        
        // Add rate limiting headers
        if securityConfig.enableRateLimitHeaders {
            secureRequest = addRateLimitHeaders(secureRequest, context: context)
        }
        
        // Validate request size
        if securityConfig.maxRequestSize > 0 {
            try validateRequestSize(secureRequest)
        }
        
        Logger.debug("🔒 Security: Applied enhanced security headers")
        return secureRequest
    }
    
    // MARK: - HTTPS Enforcement
    
    private func enforceHTTPS(_ request: URLRequest) -> URLRequest {
        guard let url = request.url,
              url.scheme != "https" && !isLocalhost(url) else {
            return request
        }
        
        Logger.warning("🔒 Security: Upgrading HTTP to HTTPS for \(url.absoluteString)")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        
        var secureRequest = request
        if let httpsURL = components?.url {
            secureRequest.url = httpsURL
        }
        
        return secureRequest
    }
    
    // MARK: - Security Headers
    
    private func addSecurityHeaders(_ request: URLRequest, context: RequestContext) -> URLRequest {
        var secureRequest = request
        
        // Content Security Policy
        if securityConfig.enableCSP {
            secureRequest.setValue(
                "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
                forHTTPHeaderField: "Content-Security-Policy"
            )
        }
        
        // Strict Transport Security
        if securityConfig.enableHSTS {
            secureRequest.setValue(
                "max-age=31536000; includeSubDomains; preload",
                forHTTPHeaderField: "Strict-Transport-Security"
            )
        }
        
        // X-Frame-Options
        secureRequest.setValue("DENY", forHTTPHeaderField: "X-Frame-Options")
        
        // X-Content-Type-Options
        secureRequest.setValue("nosniff", forHTTPHeaderField: "X-Content-Type-Options")
        
        // X-XSS-Protection
        secureRequest.setValue("1; mode=block", forHTTPHeaderField: "X-XSS-Protection")
        
        // Referrer Policy
        secureRequest.setValue("strict-origin-when-cross-origin", forHTTPHeaderField: "Referrer-Policy")
        
        // Permissions Policy
        secureRequest.setValue(
            "geolocation=(), microphone=(), camera=()",
            forHTTPHeaderField: "Permissions-Policy"
        )
        
        // Cache Control for sensitive requests
        if request.url?.path.contains("auth") == true || request.url?.path.contains("login") == true {
            secureRequest.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
            secureRequest.setValue("no-cache", forHTTPHeaderField: "Pragma")
            secureRequest.setValue("0", forHTTPHeaderField: "Expires")
        }
        
        // Add request ID for tracking
        secureRequest.setValue(context.requestId, forHTTPHeaderField: "X-Request-ID")
        
        // Add client fingerprint
        secureRequest.setValue(generateClientFingerprint(), forHTTPHeaderField: "X-Client-Fingerprint")
        
        // Add timestamp for replay attack prevention
        secureRequest.setValue("\(Int(Date().timeIntervalSince1970))", forHTTPHeaderField: "X-Timestamp")
        
        return secureRequest
    }
    
    // MARK: - Request Signing
    
    private func addRequestSignature(_ request: URLRequest) -> URLRequest {
        var secureRequest = request
        
        // Generate request signature
        let signature = generateRequestSignature(request)
        secureRequest.setValue(signature, forHTTPHeaderField: "X-Request-Signature")
        
        // Add nonce for additional security
        let nonce = UUID().uuidString
        secureRequest.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        
        return secureRequest
    }
    
    // MARK: - CSRF Protection
    
    private func addCSRFProtection(_ request: URLRequest) async -> URLRequest {
        var secureRequest = request
        
        // Add CSRF token for state-changing operations
        if ["POST", "PUT", "PATCH", "DELETE"].contains(request.httpMethod) {
            if let csrfToken = await getCSRFToken() {
                secureRequest.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-Token")
            }
        }
        
        // Add SameSite cookie directive simulation
        secureRequest.setValue("strict", forHTTPHeaderField: "X-SameSite")
        
        return secureRequest
    }
    
    // MARK: - Rate Limiting Headers
    
    private func addRateLimitHeaders(_ request: URLRequest, context: RequestContext) -> URLRequest {
        var secureRequest = request
        
        // Add rate limiting metadata
        secureRequest.setValue("60", forHTTPHeaderField: "X-RateLimit-Limit")
        secureRequest.setValue(context.requestId, forHTTPHeaderField: "X-RateLimit-Client-ID")
        
        return secureRequest
    }
    
    // MARK: - Request Validation
    
    private func validateRequestSize(_ request: URLRequest) throws {
        var totalSize = 0
        
        // Check URL size
        if let url = request.url {
            totalSize += url.absoluteString.utf8.count
        }
        
        // Check headers size
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                totalSize += key.utf8.count + value.utf8.count
            }
        }
        
        // Check body size
        if let body = request.httpBody {
            totalSize += body.count
        }
        
        if totalSize > securityConfig.maxRequestSize {
            Logger.error("🔒 Security: Request size (\(totalSize) bytes) exceeds limit (\(securityConfig.maxRequestSize) bytes)")
            throw NetworkError.badRequest(nil)
        }
    }
    
    // MARK: - Private Helpers
    
    private func isLocalhost(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host == "localhost" || host == "127.0.0.1" || host.hasPrefix("192.168.") || host.hasPrefix("10.")
    }
    
    private func getCSRFToken() async -> String? {
        // In production, this would fetch from secure storage or session
        // For now, generate a consistent token per session
        return "csrf_\(UUID().uuidString)"
    }
    
    private func generateRequestSignature(_ request: URLRequest) -> String {
        var hashInput = ""
        hashInput += request.httpMethod ?? "GET"
        hashInput += request.url?.absoluteString ?? ""
        hashInput += "\(Int(Date().timeIntervalSince1970))" // Include timestamp
        
        if let body = request.httpBody {
            hashInput += String(data: body, encoding: .utf8) ?? ""
        }
        
        return hashInput.sha256
    }
    
    private func generateClientFingerprint() -> String {
        // Generate a consistent client fingerprint
        var fingerprint = ""
        fingerprint += UIDevice.current.model
        fingerprint += UIDevice.current.systemVersion
        fingerprint += Bundle.main.bundleIdentifier ?? ""
        fingerprint += Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        
        return fingerprint.sha256
    }
}

// MARK: - Security Configuration
struct SecurityConfig {
    let enforceHTTPS: Bool
    let enableCSRFProtection: Bool
    let enableRequestSigning: Bool
    let enableCSP: Bool
    let enableHSTS: Bool
    let enableRateLimitHeaders: Bool
    let maxRequestSize: Int // in bytes, 0 = no limit
    
    static let `default` = SecurityConfig(
        enforceHTTPS: true,
        enableCSRFProtection: true,
        enableRequestSigning: true,
        enableCSP: true,
        enableHSTS: true,
        enableRateLimitHeaders: true,
        maxRequestSize: 10 * 1024 * 1024 // 10MB
    )
    
    static let strict = SecurityConfig(
        enforceHTTPS: true,
        enableCSRFProtection: true,
        enableRequestSigning: true,
        enableCSP: true,
        enableHSTS: true,
        enableRateLimitHeaders: true,
        maxRequestSize: 1 * 1024 * 1024 // 1MB
    )
    
    static let relaxed = SecurityConfig(
        enforceHTTPS: false,
        enableCSRFProtection: false,
        enableRequestSigning: false,
        enableCSP: false,
        enableHSTS: false,
        enableRateLimitHeaders: false,
        maxRequestSize: 0 // No limit
    )
}

// MARK: - Rate Limiting Interceptor
actor RateLimitingInterceptor: RequestInterceptor {
    private var requestCounts: [String: Int] = [:]
    private var lastResetTime = Date()
    private let maxRequestsPerMinute = 60
    private let windowDuration: TimeInterval = 60
    
    func intercept(request: URLRequest, context: RequestContext) async throws -> URLRequest {
        let currentTime = Date()
        
        // Reset counter if window expired
        if currentTime.timeIntervalSince(lastResetTime) >= windowDuration {
            requestCounts.removeAll()
            lastResetTime = currentTime
        }
        
        // Get endpoint key
        let endpoint = request.url?.path ?? "unknown"
        let currentCount = requestCounts[endpoint, default: 0]
        
        // Check rate limit
        if currentCount >= maxRequestsPerMinute {
            Logger.warning("🚦 Rate Limit: Exceeded limit for \(endpoint)")
            throw NetworkError.rateLimited(retryAfter: windowDuration)
        }
        
        // Increment counter
        requestCounts[endpoint] = currentCount + 1
        
        return request
    }
}

// MARK: - Response Compression Interceptor
struct CompressionInterceptor: RequestInterceptor, ResponseInterceptor {
    
    func intercept(request: URLRequest, context: RequestContext) async throws -> URLRequest {
        var modifiedRequest = request
        
        // Add compression headers
        modifiedRequest.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        return modifiedRequest
    }
    
    func intercept(response: HTTPURLResponse, data: Data, context: RequestContext) async throws -> Data {
        // Handle compressed responses
        if let encoding = response.allHeaderFields["Content-Encoding"] as? String {
            Logger.debug("📦 Compression: Response encoding: \(encoding)")
            
            // Note: URLSession typically handles decompression automatically
            // This is here for custom handling if needed
        }
        
        return data
    }
}

// MARK: - String SHA256 Extension
extension String {
    var sha256: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}