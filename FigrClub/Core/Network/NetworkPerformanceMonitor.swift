//
//  NetworkPerformanceMonitor.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Performance Metrics
struct NetworkPerformanceMetrics {
    let requestId: String
    let endpoint: String
    let method: String
    let startTime: Date
    let endTime: Date
    let statusCode: Int?
    let dataSize: Int
    let cacheHit: Bool
    let deduplicationUsed: Bool
    let error: Error?
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var isSuccessful: Bool {
        return statusCode.map { 200...299 ~= $0 } ?? false
    }
    
    var isSlow: Bool {
        return duration > 3.0
    }
    
    var throughput: Double {
        guard duration > 0 else { return 0 }
        return Double(dataSize) / duration // bytes per second
    }
}

// MARK: - Performance Statistics
struct NetworkPerformanceStatistics {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var cacheHits: Int = 0
    var deduplicationHits: Int = 0
    var totalDataTransferred: Int = 0
    var totalDuration: TimeInterval = 0
    var slowRequests: Int = 0
    
    var successRate: Double {
        totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0.0
    }
    
    var cacheHitRatio: Double {
        totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    var deduplicationRatio: Double {
        totalRequests > 0 ? Double(deduplicationHits) / Double(totalRequests) : 0.0
    }
    
    var averageDuration: TimeInterval {
        totalRequests > 0 ? totalDuration / Double(totalRequests) : 0.0
    }
    
    var averageThroughput: Double {
        totalDuration > 0 ? Double(totalDataTransferred) / totalDuration : 0.0
    }
    
    var slowRequestRatio: Double {
        totalRequests > 0 ? Double(slowRequests) / Double(totalRequests) : 0.0
    }
}

// MARK: - Performance Monitor Protocol
protocol NetworkPerformanceMonitorProtocol: Sendable {
    func recordMetrics(_ metrics: NetworkPerformanceMetrics) async
    func getStatistics() async -> NetworkPerformanceStatistics
    func getTopSlowEndpoints(limit: Int) async -> [(String, TimeInterval)]
    func getRecentMetrics(limit: Int) async -> [NetworkPerformanceMetrics]
    func resetStatistics() async
}

// MARK: - Network Performance Monitor
actor NetworkPerformanceMonitor: NetworkPerformanceMonitorProtocol {
    
    // MARK: - Properties
    private var statistics = NetworkPerformanceStatistics()
    private var recentMetrics: [NetworkPerformanceMetrics] = []
    private var endpointPerformance: [String: [TimeInterval]] = [:]
    private let maxRecentMetrics = 100
    private let maxEndpointSamples = 50
    
    // MARK: - Recording
    func recordMetrics(_ metrics: NetworkPerformanceMetrics) async {
        // Update statistics
        statistics.totalRequests += 1
        statistics.totalDuration += metrics.duration
        statistics.totalDataTransferred += metrics.dataSize
        
        if metrics.isSuccessful {
            statistics.successfulRequests += 1
        } else {
            statistics.failedRequests += 1
        }
        
        if metrics.cacheHit {
            statistics.cacheHits += 1
        }
        
        if metrics.deduplicationUsed {
            statistics.deduplicationHits += 1
        }
        
        if metrics.isSlow {
            statistics.slowRequests += 1
        }
        
        // Store recent metrics
        recentMetrics.append(metrics)
        if recentMetrics.count > maxRecentMetrics {
            recentMetrics.removeFirst()
        }
        
        // Track endpoint performance
        let endpointKey = "\(metrics.method) \(metrics.endpoint)"
        if endpointPerformance[endpointKey] == nil {
            endpointPerformance[endpointKey] = []
        }
        
        endpointPerformance[endpointKey]?.append(metrics.duration)
        if let count = endpointPerformance[endpointKey]?.count, count > maxEndpointSamples {
            endpointPerformance[endpointKey]?.removeFirst()
        }
        
        // Log performance warnings
        await logPerformanceWarnings(metrics)
    }
    
    // MARK: - Querying
    func getStatistics() async -> NetworkPerformanceStatistics {
        return statistics
    }
    
    func getTopSlowEndpoints(limit: Int) async -> [(String, TimeInterval)] {
        let averages = endpointPerformance.compactMap { (endpoint, durations) -> (String, TimeInterval)? in
            guard !durations.isEmpty else { return nil }
            let average = durations.reduce(0, +) / Double(durations.count)
            return (endpoint, average)
        }
        
        return Array(averages.sorted { $0.1 > $1.1 }.prefix(limit))
    }
    
    func getRecentMetrics(limit: Int) async -> [NetworkPerformanceMetrics] {
        return Array(recentMetrics.suffix(limit))
    }
    
    func resetStatistics() async {
        statistics = NetworkPerformanceStatistics()
        recentMetrics.removeAll()
        endpointPerformance.removeAll()
        Logger.info("📊 NetworkPerformanceMonitor: Statistics reset")
    }
    
    // MARK: - Analysis
    func getPerformanceInsights() async -> [String] {
        var insights: [String] = []
        
        // Cache effectiveness
        if statistics.cacheHitRatio > 0.3 {
            insights.append("✅ Cache is working well (\(Int(statistics.cacheHitRatio * 100))% hit rate)")
        } else if statistics.totalRequests > 10 {
            insights.append("⚠️ Low cache hit rate (\(Int(statistics.cacheHitRatio * 100))%) - consider adjusting cache policies")
        }
        
        // Request deduplication
        if statistics.deduplicationRatio > 0.1 {
            insights.append("✅ Request deduplication is saving \(Int(statistics.deduplicationRatio * 100))% of requests")
        }
        
        // Performance issues
        if statistics.slowRequestRatio > 0.2 {
            insights.append("🐌 \(Int(statistics.slowRequestRatio * 100))% of requests are slow (>3s)")
        }
        
        // Success rate
        if statistics.successRate < 0.95 && statistics.totalRequests > 5 {
            insights.append("❌ Success rate is \(Int(statistics.successRate * 100))% - investigate errors")
        }
        
        // Throughput
        let throughputMBps = statistics.averageThroughput / (1024 * 1024)
        if throughputMBps < 1.0 {
            insights.append("📡 Average throughput is \(String(format: "%.2f", throughputMBps)) MB/s")
        }
        
        return insights
    }
    
    // MARK: - Private Methods
    private func logPerformanceWarnings(_ metrics: NetworkPerformanceMetrics) async {
        // Slow request warning
        if metrics.isSlow {
            Logger.warning("🐌 Slow request: \(metrics.method) \(metrics.endpoint) took \(String(format: "%.3f", metrics.duration))s")
        }
        
        // Large response warning
        let sizeMB = Double(metrics.dataSize) / (1024 * 1024)
        if sizeMB > 5.0 {
            Logger.warning("📦 Large response: \(metrics.endpoint) returned \(String(format: "%.2f", sizeMB)) MB")
        }
        
        // Error logging
        if let error = metrics.error {
            Logger.error("❌ Request failed: \(metrics.endpoint) - \(error.localizedDescription)")
        }
    }
}

// MARK: - Performance Interceptor
struct PerformanceMonitoringInterceptor: RequestInterceptor, ResponseInterceptor, ErrorInterceptor {
    private let monitor: NetworkPerformanceMonitor
    
    init(monitor: NetworkPerformanceMonitor) {
        self.monitor = monitor
    }
    
    func intercept(request: URLRequest, context: RequestContext) async throws -> URLRequest {
        // Store request start info in context
        var mutableContext = context
        mutableContext.metadata["performanceStartTime"] = context.startTime
        mutableContext.metadata["requestMethod"] = request.httpMethod
        mutableContext.metadata["requestURL"] = request.url?.absoluteString
        
        return request
    }
    
    func intercept(response: HTTPURLResponse, data: Data, context: RequestContext) async throws -> Data {
        await recordSuccessMetrics(response: response, data: data, context: context, error: nil)
        return data
    }
    
    func intercept(error: Error, context: RequestContext) async -> Error {
        await recordErrorMetrics(error: error, context: context)
        return error
    }
    
    private func recordSuccessMetrics(response: HTTPURLResponse, data: Data, context: RequestContext, error: Error?) async {
        let metrics = NetworkPerformanceMetrics(
            requestId: context.requestId,
            endpoint: response.url?.path ?? context.metadata["requestURL"] as? String ?? "unknown",
            method: context.metadata["requestMethod"] as? String ?? "UNKNOWN",
            startTime: context.startTime,
            endTime: Date(),
            statusCode: response.statusCode,
            dataSize: data.count,
            cacheHit: context.metadata["cacheHit"] as? Bool ?? false,
            deduplicationUsed: context.metadata["deduplicationUsed"] as? Bool ?? false,
            error: error
        )
        
        await monitor.recordMetrics(metrics)
    }
    
    private func recordErrorMetrics(error: Error, context: RequestContext) async {
        let metrics = NetworkPerformanceMetrics(
            requestId: context.requestId,
            endpoint: context.metadata["requestURL"] as? String ?? "unknown",
            method: context.metadata["requestMethod"] as? String ?? "UNKNOWN",
            startTime: context.startTime,
            endTime: Date(),
            statusCode: nil,
            dataSize: 0,
            cacheHit: false,
            deduplicationUsed: false,
            error: error
        )
        
        await monitor.recordMetrics(metrics)
    }
}

// MARK: - Performance Dashboard (Debug)
#if DEBUG
extension NetworkPerformanceMonitor {
    
    func printPerformanceDashboard() async {
        let stats = await getStatistics()
        let insights = await getPerformanceInsights()
        let slowEndpoints = await getTopSlowEndpoints(limit: 5)
        
        print("""
        
        📊 ===== Network Performance Dashboard =====
        
        📈 GENERAL STATISTICS:
        • Total Requests: \(stats.totalRequests)
        • Success Rate: \(String(format: "%.1f", stats.successRate * 100))%
        • Average Duration: \(String(format: "%.3f", stats.averageDuration))s
        • Total Data: \(formatBytes(stats.totalDataTransferred))
        • Average Throughput: \(formatBytesPerSecond(stats.averageThroughput))
        
        🚀 OPTIMIZATION METRICS:
        • Cache Hit Rate: \(String(format: "%.1f", stats.cacheHitRatio * 100))%
        • Deduplication Rate: \(String(format: "%.1f", stats.deduplicationRatio * 100))%
        • Slow Requests: \(String(format: "%.1f", stats.slowRequestRatio * 100))%
        
        🐌 SLOWEST ENDPOINTS:
        \(slowEndpoints.map { "• \($0.0): \(String(format: "%.3f", $0.1))s" }.joined(separator: "\n"))
        
        💡 INSIGHTS:
        \(insights.map { "• \($0)" }.joined(separator: "\n"))
        
        ==========================================
        """)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatBytesPerSecond(_ bytesPerSecond: Double) -> String {
        return formatBytes(Int(bytesPerSecond)) + "/s"
    }
}
#endif

// MARK: - Enhanced Network Dispatcher Integration
extension NetworkDispatcher {
    
    private static let performanceMonitor = NetworkPerformanceMonitor()
    
    /// Setup performance monitoring
    static func setupPerformanceMonitoring() async {
        // Performance monitoring is now handled internally
        Logger.info("📊 NetworkDispatcher: Performance monitoring configured")
    }
    
    /// Get performance statistics
    static func getPerformanceStatistics() async -> NetworkPerformanceStatistics {
        return await performanceMonitor.getStatistics()
    }
    
    /// Print performance dashboard (debug only)
    #if DEBUG
    static func printPerformanceDashboard() async {
        await performanceMonitor.printPerformanceDashboard()
    }
    #endif
} 