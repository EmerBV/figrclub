//
//  NetworkLogger.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import os.log

/*
 final class NetworkLogger {
 
 // MARK: - Configuration
 private static let isEnabled: Bool = {
 #if DEBUG
 return true
 #else
 return false
 #endif
 }()
 
 private static let maxBodyLength = 1000 // Maximum characters to log for request/response bodies
 
 // MARK: - Public Methods
 
 /// Log outgoing network request
 static func logRequest(_ request: URLRequest) {
 guard isEnabled else { return }
 
 print("\n🌐 [NETWORK REQUEST] ==========================================")
 print("📤 URL: \(request.url?.absoluteString ?? "Unknown URL")")
 print("📤 Method: \(request.httpMethod ?? "Unknown Method")")
 
 // Log headers
 if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
 print("📤 Headers:")
 for (key, value) in headers {
 let sanitizedValue = sanitizeHeaderValue(key: key, value: value)
 print("   \(key): \(sanitizedValue)")
 }
 }
 
 // Log request body
 if let bodyData = request.httpBody {
 logRequestBody(bodyData)
 }
 
 print("=========================================================\n")
 }
 
 /// Log incoming network response
 static func logResponse(_ response: HTTPURLResponse, data: Data) {
 guard isEnabled else { return }
 
 let statusEmoji = getStatusEmoji(for: response.statusCode)
 
 print("\n🌐 [NETWORK RESPONSE] ========================================")
 print("📥 URL: \(response.url?.absoluteString ?? "Unknown URL")")
 print("📥 Status: \(response.statusCode) \(statusEmoji)")
 
 // Log response headers
 if !response.allHeaderFields.isEmpty {
 print("📥 Headers:")
 for (key, value) in response.allHeaderFields {
 print("   \(key): \(value)")
 }
 }
 
 // Log response body
 logResponseBody(data)
 
 print("=========================================================\n")
 }
 
 /// Log network error
 static func logError(_ error: Error, for request: URLRequest? = nil) {
 guard isEnabled else { return }
 
 print("\n❌ [NETWORK ERROR] ==========================================")
 if let url = request?.url?.absoluteString {
 print("🔗 URL: \(url)")
 }
 print("💥 Error: \(error.localizedDescription)")
 
 // Log additional error details
 if let nsError = error as NSError? {
 print("💥 Domain: \(nsError.domain)")
 print("💥 Code: \(nsError.code)")
 if !nsError.userInfo.isEmpty {
 print("💥 UserInfo: \(nsError.userInfo)")
 }
 }
 
 print("=========================================================\n")
 }
 
 // MARK: - Private Methods
 
 private static func logRequestBody(_ data: Data) {
 if let jsonString = data.prettyPrintedJSONString {
 let sanitizedJson = sanitizeJSON(jsonString)
 let truncatedJson = truncateString(sanitizedJson, maxLength: maxBodyLength)
 print("📤 Body (JSON):")
 print(truncatedJson)
 } else if let stringBody = String(data: data, encoding: .utf8) {
 let truncatedBody = truncateString(stringBody, maxLength: maxBodyLength)
 print("📤 Body (String):")
 print(truncatedBody)
 } else {
 print("📤 Body: \(data.count) bytes (binary data)")
 }
 }
 
 private static func logResponseBody(_ data: Data) {
 if data.isEmpty {
 print("📥 Body: Empty")
 return
 }
 
 if let jsonString = data.prettyPrintedJSONString {
 let sanitizedJson = sanitizeJSON(jsonString)
 let truncatedJson = truncateString(sanitizedJson, maxLength: maxBodyLength)
 print("📥 Body (JSON):")
 print(truncatedJson)
 } else if let stringBody = String(data: data, encoding: .utf8) {
 let truncatedBody = truncateString(stringBody, maxLength: maxBodyLength)
 print("📥 Body (String):")
 print(truncatedBody)
 } else {
 print("📥 Body: \(data.count) bytes (binary data)")
 }
 }
 
 private static func sanitizeHeaderValue(key: String, value: String) -> String {
 let lowercaseKey = key.lowercased()
 
 // Sanitize sensitive headers
 if lowercaseKey.contains("authorization") ||
 lowercaseKey.contains("token") ||
 lowercaseKey.contains("key") ||
 lowercaseKey.contains("secret") {
 return "***REDACTED***"
 }
 
 return value
 }
 
 private static func sanitizeJSON(_ jsonString: String) -> String {
 var sanitized = jsonString
 
 // Define sensitive field patterns
 let sensitivePatterns = [
 "\"password\"\\s*:\\s*\"[^\"]*\"",
 "\"token\"\\s*:\\s*\"[^\"]*\"",
 "\"accessToken\"\\s*:\\s*\"[^\"]*\"",
 "\"refreshToken\"\\s*:\\s*\"[^\"]*\"",
 "\"secret\"\\s*:\\s*\"[^\"]*\"",
 "\"key\"\\s*:\\s*\"[^\"]*\"",
 "\"apiKey\"\\s*:\\s*\"[^\"]*\""
 ]
 
 // Replace sensitive values
 for pattern in sensitivePatterns {
 let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
 let range = NSRange(location: 0, length: sanitized.utf16.count)
 
 if let regex = regex {
 let fieldName = extractFieldName(from: pattern)
 let replacement = "\"\(fieldName)\":\"***REDACTED***\""
 sanitized = regex.stringByReplacingMatches(
 in: sanitized,
 options: [],
 range: range,
 withTemplate: replacement
 )
 }
 }
 
 return sanitized
 }
 
 private static func extractFieldName(from pattern: String) -> String {
 // Extract field name from regex pattern
 if let range = pattern.range(of: "\"\\w+\"", options: .regularExpression) {
 let fieldWithQuotes = String(pattern[range])
 return fieldWithQuotes.replacingOccurrences(of: "\"", with: "")
 }
 return "field"
 }
 
 private static func truncateString(_ string: String, maxLength: Int) -> String {
 if string.count <= maxLength {
 return string
 }
 
 let truncated = String(string.prefix(maxLength))
 return truncated + "\n... (truncated, total length: \(string.count) characters)"
 }
 
 private static func getStatusEmoji(for statusCode: Int) -> String {
 switch statusCode {
 case 200...299:
 return "✅"
 case 300...399:
 return "🔄"
 case 400...499:
 return "⚠️"
 case 500...599:
 return "🔥"
 default:
 return "❓"
 }
 }
 }
 
 // MARK: - Data Extension for Pretty Printing JSON
 extension Data {
 var prettyPrintedJSONString: String? {
 guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
 let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
 let prettyString = String(data: prettyData, encoding: .utf8) else {
 return nil
 }
 return prettyString
 }
 }
 
 // MARK: - Network Logger Configuration
 extension NetworkLogger {
 
 /// Enable/disable network logging at runtime (useful for specific debugging scenarios)
 static func setLoggingEnabled(_ enabled: Bool) {
 // This would require making isEnabled a variable instead of computed property
 // For now, logging is controlled by DEBUG flag
 Logger.info("Network logging is controlled by DEBUG build configuration")
 }
 
 /// Log a custom network event
 static func logCustomEvent(_ message: String) {
 guard isEnabled else { return }
 print("\n🔍 [NETWORK CUSTOM] \(message)\n")
 }
 
 /// Log network performance metrics
 static func logPerformance(url: String, duration: TimeInterval, dataSize: Int) {
 guard isEnabled else { return }
 
 print("\n⏱️ [NETWORK PERFORMANCE] ===================================")
 print("🔗 URL: \(url)")
 print("⏱️ Duration: \(String(format: "%.3f", duration))s")
 print("📊 Data Size: \(formatBytes(dataSize))")
 print("🚀 Speed: \(formatBytesPerSecond(dataSize, duration: duration))")
 print("=========================================================\n")
 }
 
 private static func formatBytes(_ bytes: Int) -> String {
 let formatter = ByteCountFormatter()
 formatter.allowedUnits = [.useKB, .useMB]
 formatter.countStyle = .file
 return formatter.string(fromByteCount: Int64(bytes))
 }
 
 private static func formatBytesPerSecond(_ bytes: Int, duration: TimeInterval) -> String {
 guard duration > 0 else { return "N/A" }
 let bytesPerSecond = Double(bytes) / duration
 return formatBytes(Int(bytesPerSecond)) + "/s"
 }
 }
 
 // MARK: - Usage Examples
 #if DEBUG
 extension NetworkLogger {
 
 /// Example usage for testing
 static func testLogging() {
 // This method demonstrates how to use the logger
 // Should only be used for testing/debugging
 
 // Example request
 var request = URLRequest(url: URL(string: "https://api.example.com/login")!)
 request.httpMethod = "POST"
 request.setValue("application/json", forHTTPHeaderField: "Content-Type")
 request.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
 
 let bodyData = """
 {
 "email": "user@example.com",
 "password": "secretpassword"
 }
 """.data(using: .utf8)!
 
 request.httpBody = bodyData
 
 logRequest(request)
 
 // Example response
 let response = HTTPURLResponse(
 url: URL(string: "https://api.example.com/login")!,
 statusCode: 200,
 httpVersion: nil,
 headerFields: ["Content-Type": "application/json"]
 )!
 
 let responseData = """
 {
 "message": "Login successful",
 "data": {
 "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
 "user": {
 "id": 123,
 "email": "user@example.com"
 }
 }
 }
 """.data(using: .utf8)!
 
 logResponse(response, data: responseData)
 }
 }
 #endif
 */

// MARK: - Network Logger Implementation
final class NetworkLogger: NetworkLoggerProtocol, @unchecked Sendable {
    
    // MARK: - Configuration
    private let isEnabled: Bool
    private let maxBodyLength: Int
    private let logLevel: LogLevel
    private let logger: os.Logger
    
    enum LogLevel: Int, CaseIterable {
        case none = 0
        case error = 1
        case warning = 2
        case info = 3
        case debug = 4
        case verbose = 5
        
        var emoji: String {
            switch self {
            case .none: return ""
            case .error: return "💥"
            case .warning: return "⚠️"
            case .info: return "ℹ️"
            case .debug: return "🔍"
            case .verbose: return "📝"
            }
        }
    }
    
    // MARK: - Initialization
    init(isEnabled: Bool = true, maxBodyLength: Int = 1000, logLevel: LogLevel = .info) {
#if DEBUG
        self.isEnabled = isEnabled
        self.logLevel = logLevel
#else
        self.isEnabled = false
        self.logLevel = .error
#endif
        
        self.maxBodyLength = maxBodyLength
        self.logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "FigrClub", category: "Networking")
    }
    
    // MARK: - NetworkLoggerProtocol Implementation
    
    func logRequest(_ request: URLRequest) {
        guard isEnabled && logLevel.rawValue >= LogLevel.info.rawValue else { return }
        
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "Unknown URL"
        
        var logMessage = """
        
        🌐 [\(getCurrentTimestamp())] NETWORK REQUEST ═══════════════════════════════════════════
        📤 \(method) \(url)
        """
        
        // Log headers
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "\n📤 Headers:"
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                let sanitizedValue = sanitizeHeaderValue(key: key, value: value)
                logMessage += "\n   \(key): \(sanitizedValue)"
            }
        }
        
        // Log request body
        if let bodyData = request.httpBody {
            logMessage += logRequestBody(bodyData)
        }
        
        // Log additional request info
        logMessage += "\n📤 Timeout: \(request.timeoutInterval)s"
        if let cachePolicy = getCachePolicyDescription(request.cachePolicy) {
            logMessage += "\n📤 Cache Policy: \(cachePolicy)"
        }
        
        logMessage += "\n═══════════════════════════════════════════════════════════════════════════════\n"
        
        print(logMessage)
        logger.info("\(logMessage)")
    }
    
    func logResponse(_ response: HTTPURLResponse, data: Data) {
        guard isEnabled && logLevel.rawValue >= LogLevel.info.rawValue else { return }
        
        let statusEmoji = getStatusEmoji(for: response.statusCode)
        let url = response.url?.absoluteString ?? "Unknown URL"
        let statusText = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
        
        var logMessage = """
        
        🌐 [\(getCurrentTimestamp())] NETWORK RESPONSE ═══════════════════════════════════════════
        📥 \(response.statusCode) \(statusEmoji) \(statusText)
        📥 URL: \(url)
        """
        
        // Log response headers
        if !response.allHeaderFields.isEmpty {
            logMessage += "\n📥 Headers:"
            for (key, value) in response.allHeaderFields.sorted(by: { "\($0.key)" < "\($1.key)" }) {
                logMessage += "\n   \(key): \(value)"
            }
        }
        
        // Log response body
        logMessage += logResponseBody(data)
        
        // Log additional response info
        if let mimeType = response.mimeType {
            logMessage += "\n📥 MIME Type: \(mimeType)"
        }
        
        if let encoding = response.textEncodingName {
            logMessage += "\n📥 Encoding: \(encoding)"
        }
        
        logMessage += "\n═══════════════════════════════════════════════════════════════════════════════\n"
        
        print(logMessage)
        logger.info("\(logMessage)")
    }
    
    func logError(_ error: Error, for request: URLRequest?) {
        guard isEnabled && logLevel.rawValue >= LogLevel.error.rawValue else { return }
        
        var logMessage = """
        
        💥 [\(getCurrentTimestamp())] NETWORK ERROR ═══════════════════════════════════════════
        """
        
        if let request = request {
            let method = request.httpMethod ?? "UNKNOWN"
            let url = request.url?.absoluteString ?? "Unknown URL"
            logMessage += "\n🔗 Request: \(method) \(url)"
        }
        
        logMessage += "\n💥 Error: \(error.localizedDescription)"
        
        // Log additional error details
        if let urlError = error as? URLError {
            logMessage += "\n💥 URL Error Code: \(urlError.code.rawValue)"
            logMessage += "\n💥 URL Error Description: \(urlError.localizedDescription)"
            
            if let failingURL = urlError.failingURL {
                logMessage += "\n💥 Failing URL: \(failingURL.absoluteString)"
            }
        }
        
        if let networkError = error as? NetworkError {
            logMessage += "\n💥 Network Error Type: \(networkError)"
            logMessage += "\n💥 Is Retryable: \(networkError.isRetryable)"
        }
        
        if let nsError = error as NSError? {
            logMessage += "\n💥 Domain: \(nsError.domain)"
            logMessage += "\n💥 Code: \(nsError.code)"
            if !nsError.userInfo.isEmpty {
                logMessage += "\n💥 UserInfo: \(nsError.userInfo)"
            }
        }
        
        logMessage += "\n═══════════════════════════════════════════════════════════════════════════════\n"
        
        print(logMessage)
        logger.error("\(logMessage)")
    }
    
    func logPerformance(url: String, duration: TimeInterval, dataSize: Int) {
        guard isEnabled && logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        
        let formattedDuration = String(format: "%.3f", duration)
        let formattedSize = formatBytes(dataSize)
        let speed = dataSize > 0 ? formatBytesPerSecond(dataSize, duration: duration) : "N/A"
        
        var logMessage = """
        
        ⏱️ [\(getCurrentTimestamp())] NETWORK PERFORMANCE ═══════════════════════════════════════
        🔗 URL: \(url)
        ⏱️ Duration: \(formattedDuration)s
        📊 Data Size: \(formattedSize)
        🚀 Speed: \(speed)
        """
        
        // Performance indicators
        if duration > 3.0 {
            logMessage += "\n🐌 SLOW REQUEST (>3s)"
        } else if duration > 1.0 {
            logMessage += "\n⚠️ MODERATE SPEED (>1s)"
        } else {
            logMessage += "\n⚡ FAST REQUEST (<1s)"
        }
        
        logMessage += "\n═══════════════════════════════════════════════════════════════════════════════\n"
        
        print(logMessage)
        logger.debug("\(logMessage)")
    }
    
    // MARK: - Private Helper Methods
    
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    private func logRequestBody(_ data: Data) -> String {
        var bodyLog = ""
        
        if data.isEmpty {
            bodyLog += "\n📤 Body: Empty"
        } else if let jsonString = data.prettyPrintedJSONString {
            let sanitizedJson = sanitizeJSON(jsonString)
            let truncatedJson = truncateString(sanitizedJson, maxLength: maxBodyLength)
            bodyLog += "\n📤 Body (JSON):\n\(truncatedJson)"
        } else if let stringBody = String(data: data, encoding: .utf8) {
            let truncatedBody = truncateString(stringBody, maxLength: maxBodyLength)
            bodyLog += "\n📤 Body (String):\n\(truncatedBody)"
        } else {
            bodyLog += "\n📤 Body: \(formatBytes(data.count)) (binary data)"
        }
        
        return bodyLog
    }
    
    private func logResponseBody(_ data: Data) -> String {
        var bodyLog = ""
        
        if data.isEmpty {
            bodyLog += "\n📥 Body: Empty"
        } else if let jsonString = data.prettyPrintedJSONString {
            let sanitizedJson = sanitizeJSON(jsonString)
            let truncatedJson = truncateString(sanitizedJson, maxLength: maxBodyLength)
            bodyLog += "\n📥 Body (JSON):\n\(truncatedJson)"
        } else if let stringBody = String(data: data, encoding: .utf8) {
            let truncatedBody = truncateString(stringBody, maxLength: maxBodyLength)
            bodyLog += "\n📥 Body (String):\n\(truncatedBody)"
        } else {
            bodyLog += "\n📥 Body: \(formatBytes(data.count)) (binary data)"
        }
        
        return bodyLog
    }
    
    private func sanitizeHeaderValue(key: String, value: String) -> String {
        let lowercaseKey = key.lowercased()
        
        let sensitiveHeaders = [
            "authorization", "token", "key", "secret", "password",
            "x-api-key", "x-auth-token", "cookie", "set-cookie"
        ]
        
        if sensitiveHeaders.contains(where: lowercaseKey.contains) {
            return "***REDACTED***"
        }
        
        return value
    }
    
    private func sanitizeJSON(_ jsonString: String) -> String {
        var sanitized = jsonString
        
        // Define sensitive field patterns
        let sensitivePatterns = [
            ("password", "\"password\"\\s*:\\s*\"[^\"]*\""),
            ("token", "\"token\"\\s*:\\s*\"[^\"]*\""),
            ("accessToken", "\"accessToken\"\\s*:\\s*\"[^\"]*\""),
            ("refreshToken", "\"refreshToken\"\\s*:\\s*\"[^\"]*\""),
            ("secret", "\"secret\"\\s*:\\s*\"[^\"]*\""),
            ("key", "\"key\"\\s*:\\s*\"[^\"]*\""),
            ("apiKey", "\"apiKey\"\\s*:\\s*\"[^\"]*\""),
            ("Authorization", "\"Authorization\"\\s*:\\s*\"[^\"]*\""),
            ("cookie", "\"cookie\"\\s*:\\s*\"[^\"]*\"")
        ]
        
        // Replace sensitive values
        for (fieldName, pattern) in sensitivePatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: sanitized.utf16.count)
            
            if let regex = regex {
                let replacement = "\"\(fieldName)\":\"***REDACTED***\""
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    options: [],
                    range: range,
                    withTemplate: replacement
                )
            }
        }
        
        return sanitized
    }
    
    private func truncateString(_ string: String, maxLength: Int) -> String {
        if string.count <= maxLength {
            return string
        }
        
        let truncated = String(string.prefix(maxLength))
        return truncated + "\n... (truncated, total length: \(string.count) characters)"
    }
    
    private func getStatusEmoji(for statusCode: Int) -> String {
        switch statusCode {
        case 200...299:
            return "✅"
        case 300...399:
            return "🔄"
        case 400...499:
            return "⚠️"
        case 500...599:
            return "🔥"
        default:
            return "❓"
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatBytesPerSecond(_ bytes: Int, duration: TimeInterval) -> String {
        guard duration > 0 else { return "N/A" }
        let bytesPerSecond = Double(bytes) / duration
        return formatBytes(Int(bytesPerSecond)) + "/s"
    }
    
    private func getCachePolicyDescription(_ cachePolicy: URLRequest.CachePolicy) -> String? {
        switch cachePolicy {
        case .useProtocolCachePolicy:
            return "Use Protocol Cache Policy"
        case .reloadIgnoringLocalCacheData:
            return "Reload Ignoring Local Cache"
        case .reloadIgnoringLocalAndRemoteCacheData:
            return "Reload Ignoring All Cache"
        case .returnCacheDataElseLoad:
            return "Return Cache Data Else Load"
        case .returnCacheDataDontLoad:
            return "Return Cache Data Don't Load"
        case .reloadRevalidatingCacheData:
            return "Reload Revalidating Cache Data"
        @unknown default:
            return "Unknown Cache Policy"
        }
    }
}

// MARK: - Data Extension for Pretty Printing JSON
extension Data {
    var prettyPrintedJSONString: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }
}

// MARK: - Network Logger Factory
extension NetworkLogger {
    
    static func production() -> NetworkLogger {
        return NetworkLogger(
            isEnabled: false,
            maxBodyLength: 0,
            logLevel: .none
        )
    }
    
    static func development() -> NetworkLogger {
        return NetworkLogger(
            isEnabled: true,
            maxBodyLength: 2000,
            logLevel: .debug
        )
    }
    
    static func testing() -> NetworkLogger {
        return NetworkLogger(
            isEnabled: true,
            maxBodyLength: 500,
            logLevel: .error
        )
    }
}

// MARK: - Network Analytics (Optional Enhancement)
extension NetworkLogger {
    
    /// Log network metrics for analytics
    func logAnalytics(endpoint: String, method: String, statusCode: Int, duration: TimeInterval, dataSize: Int) {
        guard isEnabled && logLevel.rawValue >= LogLevel.verbose.rawValue else { return }
        
        let metrics = NetworkMetrics(
            endpoint: endpoint,
            method: method,
            statusCode: statusCode,
            duration: duration,
            dataSize: dataSize,
            timestamp: Date()
        )
        
        // In a real app, you might send this to analytics service
        print("📊 [Analytics] \(metrics)")
    }
}

// MARK: - Network Metrics Model
struct NetworkMetrics {
    let endpoint: String
    let method: String
    let statusCode: Int
    let duration: TimeInterval
    let dataSize: Int
    let timestamp: Date
    
    var isSuccessful: Bool {
        return 200...299 ~= statusCode
    }
    
    var isSlow: Bool {
        return duration > 3.0
    }
    
    var sizeCategory: String {
        switch dataSize {
        case 0...1024:
            return "small"
        case 1025...10240:
            return "medium"
        case 10241...102400:
            return "large"
        default:
            return "very_large"
        }
    }
}
