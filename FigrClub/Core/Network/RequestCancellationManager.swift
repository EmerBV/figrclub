//
//  RequestCancellationManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import UIKit

// MARK: - Cancellation Reason
enum CancellationReason: String, CaseIterable {
    case userInitiated = "user_initiated"
    case superseded = "superseded"
    case timeout = "timeout"
    case networkUnavailable = "network_unavailable"
    case appBackground = "app_background"
    case memoryPressure = "memory_pressure"
    case duplicate = "duplicate"
    case stale = "stale"
    
    var description: String {
        switch self {
        case .userInitiated: return "User initiated cancellation"
        case .superseded: return "Request superseded by newer request"
        case .timeout: return "Request timeout exceeded"
        case .networkUnavailable: return "Network unavailable"
        case .appBackground: return "App moved to background"
        case .memoryPressure: return "Memory pressure detected"
        case .duplicate: return "Duplicate request cancelled"
        case .stale: return "Stale request cancelled"
        }
    }
}

// MARK: - Cancellable Request
struct CancellableRequest {
    let id: String
    let endpoint: APIEndpoint
    let task: Task<Any, Error>
    let startTime: Date
    let priority: RequestPriority
    let tags: Set<String>
    
    enum RequestPriority: Int, CaseIterable {
        case background = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        var shouldPreempt: Bool {
            return self.rawValue >= RequestPriority.high.rawValue
        }
    }
    
    var age: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var isStale: Bool {
        age > 30.0 // Consider requests older than 30 seconds as stale
    }
    
    func cancel(reason: CancellationReason) {
        task.cancel()
        Logger.debug("❌ RequestCancellation: Cancelled request \(id) - \(reason.description)")
    }
}

// MARK: - Cancellation Statistics
struct CancellationStatistics {
    var totalCancellations: Int = 0
    var cancellationsByReason: [CancellationReason: Int] = [:]
    var savedRequests: Int = 0  // Requests avoided due to smart cancellation
    var averageCancellationTime: TimeInterval = 0
    
    mutating func recordCancellation(reason: CancellationReason, requestAge: TimeInterval) {
        totalCancellations += 1
        cancellationsByReason[reason, default: 0] += 1
        
        // Update average cancellation time
        let totalTime = averageCancellationTime * Double(totalCancellations - 1) + requestAge
        averageCancellationTime = totalTime / Double(totalCancellations)
    }
    
    mutating func recordSavedRequest() {
        savedRequests += 1
    }
    
    func getMostCommonCancellationReason() -> CancellationReason? {
        return cancellationsByReason.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Request Cancellation Manager Protocol
protocol RequestCancellationManagerProtocol: Sendable {
    func registerRequest(_ request: CancellableRequest) async
    func cancelRequest(id: String, reason: CancellationReason) async
    func cancelRequests(withTag tag: String, reason: CancellationReason) async
    func cancelStaleRequests() async
    func cancelLowPriorityRequests() async
    func cancelAllRequests(reason: CancellationReason) async
    func getStatistics() async -> CancellationStatistics
}

// MARK: - Request Cancellation Manager
actor RequestCancellationManager: RequestCancellationManagerProtocol {
    
    // MARK: - Properties
    private var activeRequests: [String: CancellableRequest] = [:]
    private var statistics = CancellationStatistics()
    private let config: CancellationConfig
    private var cleanupTimer: Timer?
    
    // MARK: - Configuration
    struct CancellationConfig {
        let maxConcurrentRequests: Int
        let staleRequestThreshold: TimeInterval
        let automaticCleanupInterval: TimeInterval
        let enableSmartCancellation: Bool
        let memoryPressureThreshold: Int // MB
        
        static let `default` = CancellationConfig(
            maxConcurrentRequests: 10,
            staleRequestThreshold: 30.0,
            automaticCleanupInterval: 15.0,
            enableSmartCancellation: true,
            memoryPressureThreshold: 100
        )
        
        static let aggressive = CancellationConfig(
            maxConcurrentRequests: 5,
            staleRequestThreshold: 15.0,
            automaticCleanupInterval: 10.0,
            enableSmartCancellation: true,
            memoryPressureThreshold: 50
        )
    }
    
    // MARK: - Initialization
    init(config: CancellationConfig = .default) {
        self.config = config
        startPeriodicCleanup()
        setupMemoryPressureMonitoring()
        setupAppStateMonitoring()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Request Management
    
    func registerRequest(_ request: CancellableRequest) async {
        // Check if we need to make room for new request
        if activeRequests.count >= config.maxConcurrentRequests {
            await enforceRequestLimit()
        }
        
        // Check for duplicate or superseding requests
        if config.enableSmartCancellation {
            await handleSmartCancellation(for: request)
        }
        
        activeRequests[request.id] = request
        Logger.debug("📝 RequestCancellation: Registered request \(request.id) for \(request.endpoint.path)")
    }
    
    func cancelRequest(id: String, reason: CancellationReason) async {
        guard let request = activeRequests.removeValue(forKey: id) else {
            return
        }
        
        request.cancel(reason: reason)
        statistics.recordCancellation(reason: reason, requestAge: request.age)
    }
    
    func cancelRequests(withTag tag: String, reason: CancellationReason) async {
        let requestsToCancel = activeRequests.values.filter { $0.tags.contains(tag) }
        
        for request in requestsToCancel {
            await cancelRequest(id: request.id, reason: reason)
        }
        
        Logger.info("❌ RequestCancellation: Cancelled \(requestsToCancel.count) requests with tag '\(tag)'")
    }
    
    func cancelStaleRequests() async {
        let staleRequests = activeRequests.values.filter { $0.isStale }
        
        for request in staleRequests {
            await cancelRequest(id: request.id, reason: .stale)
        }
        
        if !staleRequests.isEmpty {
            Logger.info("🧹 RequestCancellation: Cancelled \(staleRequests.count) stale requests")
        }
    }
    
    func cancelLowPriorityRequests() async {
        let lowPriorityRequests = activeRequests.values.filter { $0.priority == .background }
        
        for request in lowPriorityRequests {
            await cancelRequest(id: request.id, reason: .memoryPressure)
        }
        
        if !lowPriorityRequests.isEmpty {
            Logger.info("⚡ RequestCancellation: Cancelled \(lowPriorityRequests.count) low priority requests")
        }
    }
    
    func cancelAllRequests(reason: CancellationReason) async {
        let requestCount = activeRequests.count
        
        for request in activeRequests.values {
            request.cancel(reason: reason)
            statistics.recordCancellation(reason: reason, requestAge: request.age)
        }
        
        activeRequests.removeAll()
        Logger.warning("🚨 RequestCancellation: Cancelled all \(requestCount) requests - \(reason.description)")
    }
    
    func getStatistics() async -> CancellationStatistics {
        return statistics
    }
    
    // MARK: - Smart Cancellation Logic
    
    private func handleSmartCancellation(for newRequest: CancellableRequest) async {
        let endpoint = newRequest.endpoint
        
        // Cancel duplicate requests to same endpoint
        let duplicateRequests = activeRequests.values.filter { existingRequest in
            existingRequest.endpoint.path == endpoint.path &&
            existingRequest.endpoint.method == endpoint.method &&
            existingRequest.id != newRequest.id
        }
        
        for duplicate in duplicateRequests {
            await cancelRequest(id: duplicate.id, reason: .duplicate)
            statistics.recordSavedRequest()
        }
        
        // Cancel superseded requests (newer GET requests supersede older ones for same resource)
        if endpoint.method == .GET {
            let supersededRequests = activeRequests.values.filter { existingRequest in
                existingRequest.endpoint.path == endpoint.path &&
                existingRequest.endpoint.method == .GET &&
                existingRequest.priority.rawValue <= newRequest.priority.rawValue &&
                existingRequest.id != newRequest.id
            }
            
            for superseded in supersededRequests {
                await cancelRequest(id: superseded.id, reason: .superseded)
                statistics.recordSavedRequest()
            }
        }
    }
    
    private func enforceRequestLimit() async {
        guard activeRequests.count >= config.maxConcurrentRequests else { return }
        
        // Sort by priority (lowest first) and age (oldest first)
        let sortedRequests = activeRequests.values.sorted { first, second in
            if first.priority.rawValue != second.priority.rawValue {
                return first.priority.rawValue < second.priority.rawValue
            }
            return first.startTime < second.startTime
        }
        
        // Cancel the lowest priority, oldest request
        if let requestToCancel = sortedRequests.first {
            await cancelRequest(id: requestToCancel.id, reason: .memoryPressure)
            Logger.info("📊 RequestCancellation: Cancelled request to make room for new request")
        }
    }
    
    // MARK: - Monitoring and Cleanup
    
    private func startPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: config.automaticCleanupInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performPeriodicCleanup()
            }
        }
    }
    
    private func performPeriodicCleanup() async {
        await cancelStaleRequests()
        
        // Clean up completed requests that are no longer tracked
        let completedRequestIds = activeRequests.compactMap { (id, request) in
            request.task.isCancelled ? id : nil
        }
        
        for id in completedRequestIds {
            activeRequests.removeValue(forKey: id)
        }
        
        Logger.debug("🧹 RequestCancellation: Periodic cleanup completed - \(activeRequests.count) active requests")
    }
    
    private func setupMemoryPressureMonitoring() {
        // Monitor memory pressure and cancel low priority requests
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleMemoryPressure()
            }
        }
    }
    
    private func setupAppStateMonitoring() {
        // Cancel non-critical requests when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleAppBackground()
            }
        }
    }
    
    private func handleMemoryPressure() async {
        Logger.warning("⚠️ RequestCancellation: Memory pressure detected")
        await cancelLowPriorityRequests()
    }
    
    private func handleAppBackground() async {
        // Cancel non-critical background requests when app goes to background
        let backgroundRequests = activeRequests.values.filter { request in
            request.priority == .background && !request.endpoint.isBackgroundEssential
        }
        
        for request in backgroundRequests {
            await cancelRequest(id: request.id, reason: .appBackground)
        }
        
        Logger.info("📱 RequestCancellation: Cancelled \(backgroundRequests.count) background requests")
    }
}

// MARK: - Enhanced Network Dispatcher with Cancellation Support
extension NetworkDispatcher {
    
    /// Dispatch with intelligent cancellation support
    func dispatchWithCancellation<T: Codable>(
        _ endpoint: APIEndpoint,
        priority: CancellableRequest.RequestPriority = .normal,
        tags: Set<String> = [],
        cancellationManager: RequestCancellationManager
    ) async throws -> T {
        let requestId = UUID().uuidString
        
        // Create cancellable task
        let task = Task<T, Error> {
            try await self.dispatch(endpoint)
        }
        
        // Create cancellable request
        let cancellableRequest = CancellableRequest(
            id: requestId,
            endpoint: endpoint,
            task: task as! Task<Any, Error>,
            startTime: Date(),
            priority: priority,
            tags: tags
        )
        
        // Register with cancellation manager
        await cancellationManager.registerRequest(cancellableRequest)
        
        do {
            let result = try await task.value
            return result
        } catch {
            // Clean up registration if request failed
            await cancellationManager.cancelRequest(id: requestId, reason: .userInitiated)
            throw error
        }
    }
    
    /// Cancel requests by tag
    func cancelRequests(withTag tag: String, cancellationManager: RequestCancellationManager) async {
        await cancellationManager.cancelRequests(withTag: tag, reason: .userInitiated)
    }
}

// MARK: - APIEndpoint Cancellation Configuration
extension APIEndpoint {
    /// Whether this endpoint is essential during background operations
    var isBackgroundEssential: Bool {
        // Critical operations that should continue in background
        return path.contains("auth") || 
               path.contains("upload") || 
               path.contains("sync") ||
               method != .GET
    }
    
    /// Default priority for this endpoint
    var defaultCancellationPriority: CancellableRequest.RequestPriority {
        if path.contains("auth") || path.contains("login") {
            return .critical
        } else if path.contains("user") || path.contains("profile") {
            return .high
        } else if method == .GET {
            return .normal
        } else {
            return .high // Write operations are generally high priority
        }
    }
    
    /// Default tags for categorizing requests
    var defaultTags: Set<String> {
        var tags: Set<String> = []
        
        if path.contains("auth") {
            tags.insert("auth")
        }
        if path.contains("user") {
            tags.insert("user")
        }
        if path.contains("post") {
            tags.insert("content")
        }
        if method == .GET {
            tags.insert("read")
        } else {
            tags.insert("write")
        }
        
        return tags
    }
}

// MARK: - Request Tagging Helpers
struct RequestTags {
    static let auth = "auth"
    static let user = "user"
    static let content = "content"
    static let search = "search"
    static let upload = "upload"
    static let download = "download"
    static let sync = "sync"
    static let analytics = "analytics"
    
    static func screen(_ screenName: String) -> String {
        return "screen_\(screenName)"
    }
    
    static func feature(_ featureName: String) -> String {
        return "feature_\(featureName)"
    }
}

// MARK: - Debug Support
#if DEBUG
extension RequestCancellationManager {
    
    func printCancellationStatistics() async {
        let stats = await getStatistics()
        let activeCount = activeRequests.count
        
        print("""
        
        ❌ ===== Request Cancellation Statistics =====
        
        📊 OVERVIEW:
        • Active Requests: \(activeCount)
        • Total Cancellations: \(stats.totalCancellations)
        • Saved Requests: \(stats.savedRequests)
        • Avg Cancellation Time: \(String(format: "%.2f", stats.averageCancellationTime))s
        
        📋 CANCELLATION REASONS:
        """)
        
        for reason in CancellationReason.allCases {
            let count = stats.cancellationsByReason[reason, default: 0]
            if count > 0 {
                print("  • \(reason.description): \(count)")
            }
        }
        
        if let mostCommon = stats.getMostCommonCancellationReason() {
            print("\n🔝 Most Common: \(mostCommon.description)")
        }
        
        print("==========================================\n")
    }
    
    func getActiveRequestsSummary() async -> [String] {
        return activeRequests.values.map { request in
            let age = String(format: "%.1f", request.age)
            return "\(request.priority) - \(request.endpoint.path) (\(age)s)"
        }
    }
}
#endif 