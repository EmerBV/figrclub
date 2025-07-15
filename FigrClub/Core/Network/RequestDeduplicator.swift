//
//  RequestDeduplicator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Request Deduplicator
actor RequestDeduplicator {
    
    // MARK: - Properties
    private var pendingRequests: [String: Task<Data, Error>] = [:]
    private var statistics = DeduplicationStatistics()
    
    // MARK: - Statistics
    struct DeduplicationStatistics {
        var totalRequests: Int = 0
        var duplicatedRequests: Int = 0
        var savedRequests: Int = 0
        
        var deduplicationRatio: Double {
            totalRequests > 0 ? Double(duplicatedRequests) / Double(totalRequests) : 0.0
        }
        
        mutating func recordRequest() {
            totalRequests += 1
        }
        
        mutating func recordDuplicate() {
            duplicatedRequests += 1
            savedRequests += 1
        }
    }
    
    // MARK: - Public Methods
    
    /// Execute request with deduplication
    func executeRequest(
        for key: String,
        request: @escaping () async throws -> Data
    ) async throws -> Data {
        statistics.recordRequest()
        
        // Check if there's already a pending request for this key
        if let existingTask = pendingRequests[key] {
            statistics.recordDuplicate()
            Logger.debug("🔄 RequestDeduplicator: Joining existing request for key: \(key)")
            
            do {
                let result = try await existingTask.value
                return result
            } catch {
                // If the existing request failed, remove it and retry
                pendingRequests.removeValue(forKey: key)
                throw error
            }
        }
        
        // Create new request task
        let task = Task<Data, Error> {
            do {
                let result = try await request()
                // Remove from pending requests when completed
                await removePendingRequest(for: key)
                return result
            } catch {
                // Remove from pending requests when failed
                await removePendingRequest(for: key)
                throw error
            }
        }
        
        pendingRequests[key] = task
        Logger.debug("🆕 RequestDeduplicator: Starting new request for key: \(key)")
        
        return try await task.value
    }
    
    /// Cancel all pending requests
    func cancelAllRequests() {
        for (key, task) in pendingRequests {
            task.cancel()
            Logger.debug("❌ RequestDeduplicator: Cancelled request for key: \(key)")
        }
        pendingRequests.removeAll()
    }
    
    /// Cancel specific request
    func cancelRequest(for key: String) {
        if let task = pendingRequests.removeValue(forKey: key) {
            task.cancel()
            Logger.debug("❌ RequestDeduplicator: Cancelled specific request for key: \(key)")
        }
    }
    
    /// Get current statistics
    func getStatistics() -> DeduplicationStatistics {
        return statistics
    }
    
    /// Get pending requests count
    func getPendingRequestsCount() -> Int {
        return pendingRequests.count
    }
    
    // MARK: - Private Methods
    
    private func removePendingRequest(for key: String) {
        pendingRequests.removeValue(forKey: key)
    }
}

// MARK: - Deduplication Key Generator
struct DeduplicationKeyGenerator {
    
    /// Generate deduplication key for endpoint
    static func generateKey(for endpoint: APIEndpoint) -> String {
        var components = [
            endpoint.method.rawValue,
            endpoint.path
        ]
        
        // Add query parameters to key for GET requests
        if endpoint.method == .GET, let queryParams = endpoint.queryParameters {
            let sortedParams = queryParams.sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            components.append(sortedParams)
        }
        
        // Add body hash for POST/PUT requests
        if let body = endpoint.body {
            let bodyData = try? JSONSerialization.data(withJSONObject: body)
            let bodyHash = bodyData?.sha256 ?? "no-body"
            components.append(bodyHash)
        }
        
        return components.joined(separator: "|")
    }
}

// MARK: - Data Extension for SHA256
extension Data {
    var sha256: String {
        return self.withUnsafeBytes { bytes in
            let buffer = UnsafeBufferPointer<UInt8>(start: bytes.bindMemory(to: UInt8.self).baseAddress, count: count)
            return Array(buffer).reduce("") { result, byte in
                result + String(format: "%02x", byte)
            }
        }
    }
}



// MARK: - Request Deduplication for Specific Use Cases
extension RequestDeduplicator {
    
    /// Special handling for auth requests (no deduplication for login/register)
    func shouldDeduplicateAuthRequest(_ endpoint: APIEndpoint) -> Bool {
        // Don't deduplicate login, register, or refresh token requests
        let authPaths = ["/auth/login", "/auth/register", "/auth/refresh"]
        return !authPaths.contains(endpoint.path)
    }
    
    /// Time-based deduplication for rapid successive calls
    func executeWithTimeWindow(
        for key: String,
        timeWindow: TimeInterval = 0.5,
        request: @escaping () async throws -> Data
    ) async throws -> Data {
        let timeKey = "\(key)|\(Int(Date().timeIntervalSince1970 / timeWindow))"
        return try await executeRequest(for: timeKey, request: request)
    }
} 