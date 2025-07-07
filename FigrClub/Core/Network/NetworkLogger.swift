//
//  NetworkLogger.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

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
