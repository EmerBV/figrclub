//
//  NetworkLogger.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import os.log

// MARK: - Network Logger Protocol
protocol NetworkLoggerProtocol: Sendable {
    func logRequest(_ request: URLRequest)
    func logResponse(_ response: HTTPURLResponse, data: Data)
    func logError(_ error: Error, for request: URLRequest?)
    func logPerformance(url: String, duration: TimeInterval, dataSize: Int)
}

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
