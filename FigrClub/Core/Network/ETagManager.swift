//
//  ETagManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - ETag Manager Protocol
protocol ETagManagerProtocol: Sendable {
    func addConditionalHeaders(to request: inout URLRequest, cacheKey: String) async
    func extractETag(from response: HTTPURLResponse) async -> String?
    func shouldUseConditionalRequest(for endpoint: APIEndpoint) async -> Bool
    func handleConditionalResponse(_ response: HTTPURLResponse, data: Data, cacheKey: String) async -> ConditionalResponseResult
    func conditionalRetrieve<T: Codable>(
        endpoint: APIEndpoint,
        using networkDispatcher: NetworkDispatcherProtocol
    ) async throws -> T
}

// MARK: - Conditional Response Result
enum ConditionalResponseResult {
    case notModified(cachedData: Data)
    case modified(newData: Data, etag: String?)
    case error(Error)
}

// MARK: - ETag Manager Implementation
actor ETagManager: ETagManagerProtocol {
    
    // MARK: - Properties
    private let cache: NetworkCacheProtocol
    private var etagStore: [String: String] = [:]
    
    // MARK: - Initialization
    init(cache: NetworkCacheProtocol) {
        self.cache = cache
    }
    
    // MARK: - Public Methods
    
    /// Add conditional headers to request if appropriate
    func addConditionalHeaders(to request: inout URLRequest, cacheKey: String) async {
        // Only add conditional headers for GET requests
        guard request.httpMethod == "GET" || request.httpMethod == nil else {
            return
        }
        
        // Check if we have a cached ETag for this request
        if let cachedEtag = etagStore[cacheKey] {
            request.setValue(cachedEtag, forHTTPHeaderField: "If-None-Match")
            Logger.debug("🏷️ ETag: Added If-None-Match header - \(cachedEtag)")
        }
        
        // Also check for Last-Modified headers if available
        if let cachedEntry = await cache.retrieve(for: cacheKey, policy: .cacheFirst) {
            let lastModified = DateFormatter.httpDateFormatter.string(from: cachedEntry.timestamp)
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
            Logger.debug("🕒 ETag: Added If-Modified-Since header - \(lastModified)")
        }
    }
    
    /// Extract ETag from response headers
    func extractETag(from response: HTTPURLResponse) async -> String? {
        // Check for strong ETag first
        if let etag = response.value(forHTTPHeaderField: "ETag") {
            return etag
        }
        
        // Check for weak ETag
        if let weakEtag = response.value(forHTTPHeaderField: "W/ETag") {
            return weakEtag
        }
        
        return nil
    }
    
    /// Determine if conditional requests should be used for this endpoint
    func shouldUseConditionalRequest(for endpoint: APIEndpoint) async -> Bool {
        // Only use conditional requests for GET requests
        guard endpoint.method == .GET else {
            return false
        }
        
        // Don't use for auth-related endpoints
        if endpoint.path.contains("auth") || endpoint.path.contains("login") {
            return false
        }
        
        // Don't use for real-time data endpoints
        if endpoint.path.contains("realtime") || endpoint.path.contains("live") {
            return false
        }
        
        // Use for most other GET requests
        return true
    }
    
    /// Handle conditional response and determine next steps
    func handleConditionalResponse(_ response: HTTPURLResponse, data: Data, cacheKey: String) async -> ConditionalResponseResult {
        let statusCode = response.statusCode
        
        switch statusCode {
        case 304: // Not Modified
            Logger.debug("📦 ETag: Resource not modified (304) - using cached data")
            
            // Get cached data
            if let cachedEntry = await cache.retrieve(for: cacheKey, policy: .cacheFirst) {
                // Update the timestamp to extend cache lifetime
                await updateCacheTimestamp(for: cacheKey, entry: cachedEntry)
                return .notModified(cachedData: cachedEntry.data)
            } else {
                // Cache miss - this shouldn't happen but handle gracefully
                Logger.warning("⚠️ ETag: 304 response but no cached data found")
                return .error(NetworkError.invalidResponse)
            }
            
        case 200...299: // Success with new data
            let newEtag = await extractETag(from: response)
            
            // Store the new ETag
            if let etag = newEtag {
                etagStore[cacheKey] = etag
                Logger.debug("🏷️ ETag: Stored new ETag - \(etag)")
            }
            
            return .modified(newData: data, etag: newEtag)
            
        default:
            // Error response
            Logger.warning("❌ ETag: Received error response - \(statusCode)")
            return .error(NetworkError.serverError(nil))
        }
    }
    
    // MARK: - Private Methods
    
    /// Update cache timestamp to extend lifetime after 304 response
    private func updateCacheTimestamp(for cacheKey: String, entry: CacheEntry) async {
        // Create updated entry with current timestamp
        let updatedEntry = CacheEntry(
            data: entry.data,
            timestamp: Date(), // Updated timestamp
            etag: entry.etag,
            maxAge: entry.maxAge,
            url: entry.url
        )
        
        // Re-store with updated timestamp
        await cache.store(
            updatedEntry.data,
            for: cacheKey,
            with: .cacheFirst,
            etag: updatedEntry.etag,
            maxAge: updatedEntry.maxAge
        )
        
        Logger.debug("🔄 ETag: Updated cache timestamp for \(cacheKey)")
    }
    
    /// Clean up old ETags that are no longer needed
    func cleanupOldETags() async {
        // This could be implemented to remove ETags for cache entries that no longer exist
        Logger.debug("🧹 ETag: Cleanup completed - \(etagStore.count) ETags stored")
    }
}

// MARK: - HTTP Date Formatter Extension
extension DateFormatter {
    static let httpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }()
}

// MARK: - Conditional Retrieve Implementation
extension ETagManager {
    
    /// Retrieve data with conditional request support
    func conditionalRetrieve<T: Codable>(
        endpoint: APIEndpoint,
        using networkDispatcher: NetworkDispatcherProtocol
    ) async throws -> T {
        // This is a simplified implementation
        // In practice, this would coordinate with NetworkDispatcher
        return try await networkDispatcher.dispatch(endpoint)
    }
}