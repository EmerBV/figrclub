//
//  NetworkAnalyticsService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Analytics Event Types
enum AnalyticsEventType {
    case requestStarted
    case requestCompleted
    case requestFailed
    case cacheHit
    case cacheMiss
    case deduplicationHit
    case rateLimitTriggered
    case retryAttempt
    case circuitBreakerOpen
    case backgroundRefresh
}

// MARK: - Analytics Event
struct NetworkAnalyticsEvent {
    let id: String
    let type: AnalyticsEventType
    let endpoint: String
    let method: String
    let timestamp: Date
    let duration: TimeInterval?
    let statusCode: Int?
    let dataSize: Int?
    let error: String?
    let metadata: [String: String]
    
    init(
        type: AnalyticsEventType,
        endpoint: String,
        method: String,
        duration: TimeInterval? = nil,
        statusCode: Int? = nil,
        dataSize: Int? = nil,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.endpoint = endpoint
        self.method = method
        self.timestamp = Date()
        self.duration = duration
        self.statusCode = statusCode
        self.dataSize = dataSize
        self.error = error
        self.metadata = metadata
    }
}

// MARK: - Analytics Aggregated Data
struct AnalyticsAggregatedData {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var totalDuration: TimeInterval = 0
    var totalDataTransferred: Int = 0
    var cacheHits: Int = 0
    var deduplicationHits: Int = 0
    var rateLimitHits: Int = 0
    var endpointMetrics: [String: EndpointMetrics] = [:]
    
    struct EndpointMetrics {
        var requestCount: Int = 0
        var successCount: Int = 0
        var failureCount: Int = 0
        var totalDuration: TimeInterval = 0
        var averageDuration: TimeInterval {
            requestCount > 0 ? totalDuration / Double(requestCount) : 0
        }
        var successRate: Double {
            requestCount > 0 ? Double(successCount) / Double(requestCount) : 0
        }
    }
    
    var successRate: Double {
        totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0
    }
    
    var averageDuration: TimeInterval {
        totalRequests > 0 ? totalDuration / Double(totalRequests) : 0
    }
    
    var cacheHitRate: Double {
        totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0
    }
    
    var deduplicationRate: Double {
        totalRequests > 0 ? Double(deduplicationHits) / Double(totalRequests) : 0
    }
}

// MARK: - Network Analytics Service Protocol
protocol NetworkAnalyticsServiceProtocol: Sendable {
    func recordEvent(_ event: NetworkAnalyticsEvent) async
    func getAggregatedData() async -> AnalyticsAggregatedData
    func getRecentEvents(limit: Int) async -> [NetworkAnalyticsEvent]
    func exportAnalytics() async -> Data?
    func clearAnalytics() async
    func getTopEndpoints(by metric: EndpointMetric, limit: Int) async -> [(String, Double)]
}

enum EndpointMetric {
    case requestCount
    case averageDuration
    case failureRate
    case dataTransferred
}

// MARK: - Network Analytics Service Implementation
actor NetworkAnalyticsService: NetworkAnalyticsServiceProtocol {
    
    // MARK: - Properties
    private var events: [NetworkAnalyticsEvent] = []
    private var aggregatedData = AnalyticsAggregatedData()
    private let maxEvents = 1000
    private let batchSize = 50
    private var eventBuffer: [NetworkAnalyticsEvent] = []
    
    // MARK: - Analytics Recording
    func recordEvent(_ event: NetworkAnalyticsEvent) async {
        // Add to buffer for batch processing
        eventBuffer.append(event)
        
        // Process immediately for real-time aggregation
        await processEvent(event)
        
        // Batch process if buffer is full
        if eventBuffer.count >= batchSize {
            await processBatch()
        }
    }
    
    // MARK: - Data Retrieval
    func getAggregatedData() async -> AnalyticsAggregatedData {
        return aggregatedData
    }
    
    func getRecentEvents(limit: Int) async -> [NetworkAnalyticsEvent] {
        let limitedCount = min(limit, events.count)
        return Array(events.suffix(limitedCount))
    }
    
    func exportAnalytics() async -> Data? {
        let exportData = AnalyticsExportData(
            timestamp: Date(),
            aggregatedData: aggregatedData,
            recentEvents: await getRecentEvents(limit: 100)
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func clearAnalytics() async {
        events.removeAll()
        eventBuffer.removeAll()
        aggregatedData = AnalyticsAggregatedData()
        Logger.info("📊 NetworkAnalytics: Analytics data cleared")
    }
    
    func getTopEndpoints(by metric: EndpointMetric, limit: Int) async -> [(String, Double)] {
        let sorted = aggregatedData.endpointMetrics.sorted { (first, second) in
            let firstValue = getValue(for: first.value, metric: metric)
            let secondValue = getValue(for: second.value, metric: metric)
            return firstValue > secondValue
        }
        
        return Array(sorted.prefix(limit)).map { (endpoint, metrics) in
            (endpoint, getValue(for: metrics, metric: metric))
        }
    }
    
    // MARK: - Private Methods
    private func processEvent(_ event: NetworkAnalyticsEvent) async {
        // Add to events list
        events.append(event)
        if events.count > maxEvents {
            events.removeFirst()
        }
        
        // Update aggregated data
        await updateAggregatedData(with: event)
        
        // Log interesting events
        await logInterestingEvent(event)
    }
    
    private func processBatch() async {
        Logger.debug("📊 NetworkAnalytics: Processing batch of \(eventBuffer.count) events")
        
        // Could send to external analytics service here
        await sendToExternalService(eventBuffer)
        
        eventBuffer.removeAll()
    }
    
    private func updateAggregatedData(with event: NetworkAnalyticsEvent) async {
        let endpointKey = "\(event.method) \(event.endpoint)"
        
        switch event.type {
        case .requestStarted:
            aggregatedData.totalRequests += 1
            
        case .requestCompleted:
            aggregatedData.successfulRequests += 1
            if let duration = event.duration {
                aggregatedData.totalDuration += duration
            }
            if let dataSize = event.dataSize {
                aggregatedData.totalDataTransferred += dataSize
            }
            
        case .requestFailed:
            aggregatedData.failedRequests += 1
            if let duration = event.duration {
                aggregatedData.totalDuration += duration
            }
            
        case .cacheHit:
            aggregatedData.cacheHits += 1
            
        case .deduplicationHit:
            aggregatedData.deduplicationHits += 1
            
        case .rateLimitTriggered:
            aggregatedData.rateLimitHits += 1
            
        default:
            break
        }
        
        // Update endpoint-specific metrics
        if aggregatedData.endpointMetrics[endpointKey] == nil {
            aggregatedData.endpointMetrics[endpointKey] = AnalyticsAggregatedData.EndpointMetrics()
        }
        
        switch event.type {
        case .requestStarted:
            aggregatedData.endpointMetrics[endpointKey]?.requestCount += 1
            
        case .requestCompleted:
            aggregatedData.endpointMetrics[endpointKey]?.successCount += 1
            if let duration = event.duration {
                aggregatedData.endpointMetrics[endpointKey]?.totalDuration += duration
            }
            
        case .requestFailed:
            aggregatedData.endpointMetrics[endpointKey]?.failureCount += 1
            if let duration = event.duration {
                aggregatedData.endpointMetrics[endpointKey]?.totalDuration += duration
            }
            
        default:
            break
        }
    }
    
    private func logInterestingEvent(_ event: NetworkAnalyticsEvent) async {
        switch event.type {
        case .requestFailed:
            Logger.warning("📊 Analytics: Request failed - \(event.endpoint) (\(event.error ?? "Unknown error"))")
            
        case .rateLimitTriggered:
            Logger.warning("📊 Analytics: Rate limit triggered - \(event.endpoint)")
            
        case .circuitBreakerOpen:
            Logger.error("📊 Analytics: Circuit breaker opened - \(event.endpoint)")
            
        case .requestCompleted:
            if let duration = event.duration, duration > 5.0 {
                Logger.warning("📊 Analytics: Slow request detected - \(event.endpoint) (\(String(format: "%.2f", duration))s)")
            }
            
        default:
            break
        }
    }
    
    private func sendToExternalService(_ events: [NetworkAnalyticsEvent]) async {
        // In a real implementation, you would send to Firebase Analytics,
        // Mixpanel, or your custom analytics backend
        #if DEBUG
        Logger.debug("📊 NetworkAnalytics: Would send \(events.count) events to external service")
        #endif
        
        // Example implementation:
        // try await analyticsAPI.sendEvents(events)
    }
    
    private func getValue(for metrics: AnalyticsAggregatedData.EndpointMetrics, metric: EndpointMetric) -> Double {
        switch metric {
        case .requestCount:
            return Double(metrics.requestCount)
        case .averageDuration:
            return metrics.averageDuration
        case .failureRate:
            return 1.0 - metrics.successRate
        case .dataTransferred:
            return 0 // Would need to track this separately
        }
    }
}

// MARK: - Analytics Export Data
private struct AnalyticsExportData: Codable {
    let timestamp: Date
    let aggregatedData: AnalyticsAggregatedData
    let recentEvents: [NetworkAnalyticsEvent]
}

// MARK: - Codable Conformance
extension AnalyticsAggregatedData: Codable {}
extension AnalyticsAggregatedData.EndpointMetrics: Codable {}
extension NetworkAnalyticsEvent: Codable {}
extension AnalyticsEventType: Codable {}

// MARK: - Analytics Dashboard (Debug Only)
#if DEBUG
extension NetworkAnalyticsService {
    
    func printAnalyticsDashboard() async {
        let data = await getAggregatedData()
        let topEndpoints = await getTopEndpoints(by: .requestCount, limit: 5)
        let slowestEndpoints = await getTopEndpoints(by: .averageDuration, limit: 5)
        
        print("""
        
        📊 ===== Network Analytics Dashboard =====
        
        📈 GENERAL METRICS:
        • Total Requests: \(data.totalRequests)
        • Success Rate: \(String(format: "%.1f", data.successRate * 100))%
        • Average Duration: \(String(format: "%.3f", data.averageDuration))s
        • Cache Hit Rate: \(String(format: "%.1f", data.cacheHitRate * 100))%
        • Deduplication Rate: \(String(format: "%.1f", data.deduplicationRate * 100))%
        
        🔥 TOP ENDPOINTS (by requests):
        \(topEndpoints.map { "• \($0.0): \(Int($0.1)) requests" }.joined(separator: "\n"))
        
        🐌 SLOWEST ENDPOINTS:
        \(slowestEndpoints.map { "• \($0.0): \(String(format: "%.3f", $0.1))s avg" }.joined(separator: "\n"))
        
        ==========================================
        """)
    }
}
#endif

// MARK: - Convenience Analytics Recording Functions
extension NetworkAnalyticsService {
    
    func recordRequestStarted(endpoint: String, method: String) async {
        let event = NetworkAnalyticsEvent(
            type: .requestStarted,
            endpoint: endpoint,
            method: method
        )
        await recordEvent(event)
    }
    
    func recordRequestCompleted(endpoint: String, method: String, duration: TimeInterval, statusCode: Int, dataSize: Int) async {
        let event = NetworkAnalyticsEvent(
            type: .requestCompleted,
            endpoint: endpoint,
            method: method,
            duration: duration,
            statusCode: statusCode,
            dataSize: dataSize
        )
        await recordEvent(event)
    }
    
    func recordRequestFailed(endpoint: String, method: String, duration: TimeInterval, error: Error) async {
        let event = NetworkAnalyticsEvent(
            type: .requestFailed,
            endpoint: endpoint,
            method: method,
            duration: duration,
            error: error.localizedDescription
        )
        await recordEvent(event)
    }
    
    func recordCacheHit(endpoint: String, method: String) async {
        let event = NetworkAnalyticsEvent(
            type: .cacheHit,
            endpoint: endpoint,
            method: method
        )
        await recordEvent(event)
    }
    
    func recordDeduplicationHit(endpoint: String, method: String) async {
        let event = NetworkAnalyticsEvent(
            type: .deduplicationHit,
            endpoint: endpoint,
            method: method
        )
        await recordEvent(event)
    }
} 