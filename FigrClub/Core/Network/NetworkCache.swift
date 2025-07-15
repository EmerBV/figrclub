//
//  NetworkCache.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Cache Policy
enum CachePolicy {
    case noCache
    case cacheFirst        // Usa cache si existe, luego network
    case networkFirst      // Usa network si es posible, luego cache
    case cacheOnly         // Solo usa cache
    case networkOnly       // Solo usa network, actualiza cache
    case staleWhileRevalidate // Retorna cache inmediatamente, actualiza en background
}

// MARK: - Cache Entry
struct CacheEntry {
    let data: Data
    let timestamp: Date
    let etag: String?
    let maxAge: TimeInterval
    let url: String
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > maxAge
    }
    
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Cache Statistics
struct CacheStatistics {
    var hitCount: Int = 0
    var missCount: Int = 0
    var evictionCount: Int = 0
    var totalRequests: Int = 0
    
    var hitRatio: Double {
        totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0.0
    }
    
    mutating func recordHit() {
        hitCount += 1
        totalRequests += 1
    }
    
    mutating func recordMiss() {
        missCount += 1
        totalRequests += 1
    }
    
    mutating func recordEviction() {
        evictionCount += 1
    }
}

// MARK: - Network Cache Protocol
protocol NetworkCacheProtocol: Sendable {
    func store(_ data: Data, for url: String, with policy: CachePolicy, etag: String?, maxAge: TimeInterval) async
    func retrieve(for url: String, policy: CachePolicy) async -> CacheEntry?
    func conditionalRetrieve(for url: String, ifNoneMatch etag: String?) async -> CacheConditionalResult?
    func remove(for url: String) async
    func clearAll() async
    func getStatistics() async -> CacheStatistics
}

// MARK: - Cache Conditional Result
enum CacheConditionalResult {
    case notModified(CacheEntry)
    case modified
    case notFound
}

// MARK: - Network Cache Implementation
actor NetworkCache: NetworkCacheProtocol {
    
    // MARK: - Properties
    private var cache: [String: CacheEntry] = [:]
    private var statistics = CacheStatistics()
    private let maxMemorySize: Int
    private let defaultMaxAge: TimeInterval
    private var currentMemoryUsage: Int = 0
    
    // MARK: - Initialization
    init(maxMemorySize: Int = 50 * 1024 * 1024, defaultMaxAge: TimeInterval = 300) { // 50MB default
        self.maxMemorySize = maxMemorySize
        self.defaultMaxAge = defaultMaxAge
        
        // Cleanup expired entries periodically
        Task {
            await schedulePeriodicCleanup()
        }
    }
    
    // MARK: - Cache Operations
    
    func store(_ data: Data, for url: String, with policy: CachePolicy, etag: String? = nil, maxAge: TimeInterval = 0) async {
        guard policy != .noCache && policy != .networkOnly else { return }
        
        let actualMaxAge = maxAge > 0 ? maxAge : defaultMaxAge
        let entry = CacheEntry(
            data: data,
            timestamp: Date(),
            etag: etag,
            maxAge: actualMaxAge,
            url: url
        )
        
        // Remove old entry if exists
        if cache[url] != nil {
            await remove(for: url)
        }
        
        // Check if we have enough memory
        let dataSize = data.count
        if currentMemoryUsage + dataSize > maxMemorySize {
            await evictLeastRecentlyUsed(targetSize: dataSize)
        }
        
        cache[url] = entry
        currentMemoryUsage += dataSize
        
        Logger.debug("💾 NetworkCache: Stored \(formatBytes(dataSize)) for \(url)")
    }
    
    func retrieve(for url: String, policy: CachePolicy) async -> CacheEntry? {
        guard policy != .noCache && policy != .networkOnly else {
            statistics.recordMiss()
            return nil
        }
        
        guard let entry = cache[url] else {
            statistics.recordMiss()
            Logger.debug("💾 NetworkCache: Miss for \(url)")
            return nil
        }
        
        // Check if entry is expired
        if entry.isExpired {
            statistics.recordMiss()
            await remove(for: url)
            Logger.debug("💾 NetworkCache: Expired entry for \(url)")
            return nil
        }
        
        statistics.recordHit()
        Logger.debug("💾 NetworkCache: Hit for \(url) (age: \(String(format: "%.1f", entry.age))s)")
        return entry
    }
    
    func conditionalRetrieve(for url: String, ifNoneMatch etag: String?) async -> CacheConditionalResult? {
        guard let entry = cache[url] else {
            Logger.debug("💾 NetworkCache: No cached entry for conditional request - \(url)")
            return .notFound
        }
        
        // If no etag provided, treat as modified
        guard let etag = etag else {
            return .modified
        }
        
        // Compare ETags
        if let cachedEtag = entry.etag, cachedEtag == etag {
            statistics.recordHit()
            Logger.debug("💾 NetworkCache: ETag match (304) for \(url) - \(etag)")
            return .notModified(entry)
        } else {
            Logger.debug("💾 NetworkCache: ETag mismatch for \(url) - cached: \(entry.etag ?? "none"), request: \(etag)")
            return .modified
        }
    }
    
    func remove(for url: String) async {
        if let entry = cache.removeValue(forKey: url) {
            currentMemoryUsage -= entry.data.count
            Logger.debug("💾 NetworkCache: Removed \(url)")
        }
    }
    
    func clearAll() async {
        cache.removeAll()
        currentMemoryUsage = 0
        statistics.evictionCount += cache.count
        Logger.debug("💾 NetworkCache: Cleared all entries")
    }
    
    func getStatistics() async -> CacheStatistics {
        return statistics
    }
    
    // MARK: - Private Methods
    
    private func evictLeastRecentlyUsed(targetSize: Int) async {
        let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        var freedSpace = 0
        
        for (url, entry) in sortedEntries {
            if freedSpace >= targetSize { break }
            
            cache.removeValue(forKey: url)
            freedSpace += entry.data.count
            currentMemoryUsage -= entry.data.count
            statistics.recordEviction()
            
            Logger.debug("💾 NetworkCache: Evicted \(url) (freed: \(formatBytes(entry.data.count)))")
        }
    }
    
    private func schedulePeriodicCleanup() async {
        while true {
            try? await Task.sleep(for: .seconds(300)) // Every 5 minutes
            await cleanupExpiredEntries()
        }
    }
    
    private func cleanupExpiredEntries() async {
        let expiredKeys = cache.compactMap { (key, entry) in
            entry.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            await remove(for: key)
        }
        
        if !expiredKeys.isEmpty {
            Logger.debug("💾 NetworkCache: Cleaned up \(expiredKeys.count) expired entries")
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}


 