//
//  OfflineRequestQueue.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import Network

// MARK: - Serializable Endpoint Representation
struct SerializableEndpoint: Codable {
    let path: String
    let method: String
    let headers: [String: String]
    let body: [String: String]?
    let queryParameters: [String: String]?
    let requiresAuth: Bool
    let isRefreshTokenEndpoint: Bool
}

// MARK: - Offline Request Model
struct OfflineRequest: Identifiable {
    let id: String
    let endpoint: APIEndpoint
    let timestamp: Date
    let priority: QueuePriority
    let retryCount: Int
    let maxRetries: Int
    let requestData: Data?
    let expiresAt: Date?
    
    enum QueuePriority: Int, Codable, CaseIterable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        var description: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var shouldRetry: Bool {
        return retryCount < maxRetries && !isExpired
    }
    
    func withIncrementedRetry() -> OfflineRequest {
        return OfflineRequest(
            id: id,
            endpoint: endpoint,
            timestamp: timestamp,
            priority: priority,
            retryCount: retryCount + 1,
            maxRetries: maxRetries,
            requestData: requestData,
            expiresAt: expiresAt
        )
    }
}

// MARK: - OfflineRequest Codable Implementation
extension OfflineRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, priority, retryCount, maxRetries, requestData, expiresAt
        case endpointPath, endpointMethod, endpointHeaders, endpointBody, endpointQueryParameters
        case endpointRequiresAuth, endpointIsRefreshTokenEndpoint
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        priority = try container.decode(QueuePriority.self, forKey: .priority)
        retryCount = try container.decode(Int.self, forKey: .retryCount)
        maxRetries = try container.decode(Int.self, forKey: .maxRetries)
        requestData = try container.decodeIfPresent(Data.self, forKey: .requestData)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        
        // Create a simple endpoint implementation
        let path = try container.decode(String.self, forKey: .endpointPath)
        let method = try container.decode(String.self, forKey: .endpointMethod)
        let headers = try container.decode([String: String].self, forKey: .endpointHeaders)
        let body = try container.decodeIfPresent([String: String].self, forKey: .endpointBody)
        let queryParameters = try container.decodeIfPresent([String: String].self, forKey: .endpointQueryParameters)
        let requiresAuth = try container.decode(Bool.self, forKey: .endpointRequiresAuth)
        let isRefreshTokenEndpoint = try container.decode(Bool.self, forKey: .endpointIsRefreshTokenEndpoint)
        
        self.endpoint = SimpleEndpoint(
            path: path,
            method: HTTPMethod(rawValue: method) ?? .GET,
            headers: headers,
            body: body?.mapValues { $0 },
            queryParameters: queryParameters?.mapValues { $0 },
            requiresAuth: requiresAuth,
            isRefreshTokenEndpoint: isRefreshTokenEndpoint
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(priority, forKey: .priority)
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(maxRetries, forKey: .maxRetries)
        try container.encodeIfPresent(requestData, forKey: .requestData)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        
        // Encode endpoint properties
        try container.encode(endpoint.path, forKey: .endpointPath)
        try container.encode(endpoint.method.rawValue, forKey: .endpointMethod)
        try container.encode(endpoint.headers, forKey: .endpointHeaders)
        
        // Convert [String: Any] to [String: String] for serialization
        if let body = endpoint.body {
            let stringBody = body.compactMapValues { "\($0)" }
            try container.encode(stringBody, forKey: .endpointBody)
        }
        
        if let queryParams = endpoint.queryParameters {
            let stringParams = queryParams.compactMapValues { "\($0)" }
            try container.encode(stringParams, forKey: .endpointQueryParameters)
        }
        
        try container.encode(endpoint.requiresAuth, forKey: .endpointRequiresAuth)
        try container.encode(endpoint.isRefreshTokenEndpoint, forKey: .endpointIsRefreshTokenEndpoint)
    }
}

// MARK: - Simple Endpoint Implementation for Deserialization
private struct SimpleEndpoint: APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let body: [String: Any]?
    let queryParameters: [String: Any]?
    let requiresAuth: Bool
    let isRefreshTokenEndpoint: Bool
    let retryPolicy: RetryPolicy = .default
    let cachePolicy: CachePolicy = .cacheFirst
    let cacheMaxAge: TimeInterval = 300
}

// MARK: - Queue Statistics
struct OfflineQueueStatistics {
    var totalQueued: Int = 0
    var totalProcessed: Int = 0
    var totalFailed: Int = 0
    var currentQueueSize: Int = 0
    var oldestRequestAge: TimeInterval = 0
    var averageProcessingTime: TimeInterval = 0
    
    var successRate: Double {
        let total = totalProcessed + totalFailed
        return total > 0 ? Double(totalProcessed) / Double(total) : 0.0
    }
    
    mutating func recordQueued() {
        totalQueued += 1
        currentQueueSize += 1
    }
    
    mutating func recordProcessed(processingTime: TimeInterval) {
        totalProcessed += 1
        currentQueueSize = max(0, currentQueueSize - 1)
        
        // Update average processing time
        let totalProcessingTime = averageProcessingTime * Double(totalProcessed - 1) + processingTime
        averageProcessingTime = totalProcessingTime / Double(totalProcessed)
    }
    
    mutating func recordFailed() {
        totalFailed += 1
        currentQueueSize = max(0, currentQueueSize - 1)
    }
}

// MARK: - Network Connectivity Monitor
actor NetworkConnectivityMonitor: ObservableObject {
    
    // MARK: - Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published private(set) var isConnected = false
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        var description: String {
            switch self {
            case .wifi: return "WiFi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
        Logger.debug("📶 NetworkMonitor: Started monitoring connectivity")
    }
    
    func stopMonitoring() {
        monitor.cancel()
        Logger.debug("📶 NetworkMonitor: Stopped monitoring connectivity")
    }
    
    func getCurrentStatus() async -> (isConnected: Bool, type: ConnectionType) {
        return (isConnected, connectionType)
    }
    
    func isNetworkConnected() async -> Bool {
        let status = await getCurrentStatus()
        return status.isConnected
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionStatus(_ path: NWPath) async {
        let wasConnected = isConnected
        
        isConnected = path.status == .satisfied
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
        
        // Log connectivity changes
        if wasConnected != isConnected {
            if isConnected {
                Logger.info("📶 NetworkMonitor: Connected via \(connectionType.description)")
            } else {
                Logger.warning("📶 NetworkMonitor: Disconnected")
            }
        }
    }
}

// MARK: - Offline Request Queue Protocol
protocol OfflineRequestQueueProtocol: Sendable {
    func enqueue(_ request: OfflineRequest) async
    func processQueue() async
    func clearQueue() async
    func getQueuedRequests() async -> [OfflineRequest]
    func getStatistics() async -> OfflineQueueStatistics
    func removeExpiredRequests() async
}

// MARK: - Offline Request Queue Implementation
actor OfflineRequestQueue: OfflineRequestQueueProtocol {
    
    // MARK: - Properties
    private var queue: [OfflineRequest] = []
    private var statistics = OfflineQueueStatistics()
    private let networkMonitor: NetworkConnectivityMonitor
    private let storage: OfflineStorageProtocol
    private let maxQueueSize: Int
    private let processingInterval: TimeInterval
    private var isProcessing = false
    private var processingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(
        networkMonitor: NetworkConnectivityMonitor,
        storage: OfflineStorageProtocol = OfflineStorage(),
        maxQueueSize: Int = 100,
        processingInterval: TimeInterval = 5.0
    ) {
        self.networkMonitor = networkMonitor
        self.storage = storage
        self.maxQueueSize = maxQueueSize
        self.processingInterval = processingInterval
        
        // Load persisted requests
        Task {
            await loadPersistedRequests()
            await startProcessing()
        }
    }
    
    deinit {
        processingTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func enqueue(_ request: OfflineRequest) async {
        // Check if queue is full
        if queue.count >= maxQueueSize {
            // Remove oldest low-priority request to make space
            if let oldestLowPriorityIndex = queue.firstIndex(where: { $0.priority == .low }) {
                queue.remove(at: oldestLowPriorityIndex)
                Logger.warning("📦 OfflineQueue: Removed oldest low-priority request due to queue size limit")
            } else {
                Logger.warning("📦 OfflineQueue: Queue full, cannot enqueue request")
                return
            }
        }
        
        // Add request to queue sorted by priority and timestamp
        insertSorted(request)
        statistics.recordQueued()
        
        // Persist queue
        await storage.saveRequests(queue)
        
        Logger.debug("📦 OfflineQueue: Enqueued \(request.priority.description) priority request - \(request.endpoint.path)")
        
        // Try to process immediately if connected
        if await networkMonitor.getCurrentStatus().isConnected {
            await processQueue()
        }
    }
    
    func processQueue() async {
        guard !isProcessing else { return }
        guard await networkMonitor.getCurrentStatus().isConnected else {
            Logger.debug("📦 OfflineQueue: Not processing - offline")
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.debug("📦 OfflineQueue: Starting queue processing - \(queue.count) requests")
        
        var processedCount = 0
        var failedCount = 0
        
        // Process requests in priority order
        while !queue.isEmpty {
            let connectionStatus = await networkMonitor.getCurrentStatus()
            guard connectionStatus.isConnected else { break }
            let request = queue.removeFirst()
            
            // Skip expired requests
            if request.isExpired {
                statistics.recordFailed()
                Logger.debug("📦 OfflineQueue: Skipped expired request - \(request.endpoint.path)")
                continue
            }
            
            let startTime = Date()
            
            do {
                // Attempt to execute the request
                try await executeRequest(request)
                
                let processingTime = Date().timeIntervalSince(startTime)
                statistics.recordProcessed(processingTime: processingTime)
                processedCount += 1
                
                Logger.debug("✅ OfflineQueue: Successfully processed request - \(request.endpoint.path)")
                
            } catch {
                let updatedRequest = request.withIncrementedRetry()
                
                if updatedRequest.shouldRetry {
                    // Re-queue with higher retry count
                    insertSorted(updatedRequest)
                    Logger.warning("⚠️ OfflineQueue: Retrying request (\(updatedRequest.retryCount)/\(updatedRequest.maxRetries)) - \(request.endpoint.path)")
                } else {
                    // Max retries reached
                    statistics.recordFailed()
                    failedCount += 1
                    Logger.error("❌ OfflineQueue: Failed request after max retries - \(request.endpoint.path): \(error.localizedDescription)")
                }
            }
        }
        
        // Persist updated queue
        await storage.saveRequests(queue)
        
        Logger.info("📦 OfflineQueue: Processing completed - \(processedCount) processed, \(failedCount) failed")
    }
    
    func clearQueue() async {
        queue.removeAll()
        await storage.clearRequests()
        statistics = OfflineQueueStatistics()
        Logger.info("📦 OfflineQueue: Queue cleared")
    }
    
    func getQueuedRequests() async -> [OfflineRequest] {
        return queue
    }
    
    func getStatistics() async -> OfflineQueueStatistics {
        var currentStats = statistics
        currentStats.currentQueueSize = queue.count
        
        if let oldestRequest = queue.min(by: { $0.timestamp < $1.timestamp }) {
            currentStats.oldestRequestAge = Date().timeIntervalSince(oldestRequest.timestamp)
        }
        
        return currentStats
    }
    
    func isNetworkConnected() async -> Bool {
        let status = await networkMonitor.getCurrentStatus()
        return status.isConnected
    }
    
    func removeExpiredRequests() async {
        let initialCount = queue.count
        queue.removeAll { $0.isExpired }
        let removedCount = initialCount - queue.count
        
        if removedCount > 0 {
            await storage.saveRequests(queue)
            Logger.debug("📦 OfflineQueue: Removed \(removedCount) expired requests")
        }
    }
    
    // MARK: - Private Methods
    
    private func insertSorted(_ request: OfflineRequest) {
        // Insert request maintaining priority order (critical first, then by timestamp)
        let insertIndex = queue.firstIndex { existingRequest in
            if request.priority.rawValue > existingRequest.priority.rawValue {
                return true
            } else if request.priority.rawValue == existingRequest.priority.rawValue {
                return request.timestamp < existingRequest.timestamp
            }
            return false
        } ?? queue.count
        
        queue.insert(request, at: insertIndex)
    }
    
    private func executeRequest(_ request: OfflineRequest) async throws {
        // This would execute the actual network request
        // For now, simulate execution
        Logger.debug("🌐 OfflineQueue: Executing request - \(request.endpoint.path)")
        
        // Simulate network request
        try await Task.sleep(for: .milliseconds(100))
        
        // TODO: Integrate with actual NetworkDispatcher
        // let result = try await networkDispatcher.dispatch(request.endpoint)
    }
    
    private func loadPersistedRequests() async {
        do {
            queue = try await storage.loadRequests()
            statistics.currentQueueSize = queue.count
            Logger.debug("📦 OfflineQueue: Loaded \(queue.count) persisted requests")
        } catch {
            Logger.error("❌ OfflineQueue: Failed to load persisted requests - \(error.localizedDescription)")
        }
    }
    
    private func startProcessing() async {
        processingTask = Task {
            while !Task.isCancelled {
                // Wait for processing interval
                try? await Task.sleep(for: .seconds(processingInterval))
                
                // Remove expired requests
                await removeExpiredRequests()
                
                // Process queue if connected
                if await networkMonitor.getCurrentStatus().isConnected {
                    await processQueue()
                }
            }
        }
    }
}

// MARK: - Offline Storage Protocol
protocol OfflineStorageProtocol: Sendable {
    func saveRequests(_ requests: [OfflineRequest]) async
    func loadRequests() async throws -> [OfflineRequest]
    func clearRequests() async
}

// MARK: - Offline Storage Implementation
actor OfflineStorage: OfflineStorageProtocol {
    
    private let fileURL: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("offline_requests.json")
    }
    
    func saveRequests(_ requests: [OfflineRequest]) async {
        do {
            let data = try JSONEncoder().encode(requests)
            try data.write(to: fileURL)
            Logger.debug("💾 OfflineStorage: Saved \(requests.count) requests")
        } catch {
            Logger.error("❌ OfflineStorage: Failed to save requests - \(error.localizedDescription)")
        }
    }
    
    func loadRequests() async throws -> [OfflineRequest] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        let requests = try JSONDecoder().decode([OfflineRequest].self, from: data)
        return requests
    }
    
    func clearRequests() async {
        try? FileManager.default.removeItem(at: fileURL)
        Logger.debug("💾 OfflineStorage: Cleared persisted requests")
    }
}

// MARK: - Enhanced Network Dispatcher with Offline Support
extension NetworkDispatcher {
    
    /// Dispatch with offline queue support
    func dispatchWithOfflineSupport<T: Codable>(
        _ endpoint: APIEndpoint,
        offlineQueue: OfflineRequestQueue,
        priority: OfflineRequest.QueuePriority = .normal
    ) async throws -> T {
        // Check connectivity
        let isConnected = await offlineQueue.isNetworkConnected()
        
        if isConnected {
            // Try direct request first
            do {
                return try await dispatch(endpoint)
            } catch {
                // If request fails and it's suitable for queuing, queue it
                if shouldQueueRequest(endpoint: endpoint, error: error) {
                    await queueRequestForLater(endpoint: endpoint, queue: offlineQueue, priority: priority)
                }
                throw error
            }
        } else {
            // Offline - queue the request
            await queueRequestForLater(endpoint: endpoint, queue: offlineQueue, priority: priority)
            throw NetworkError.noInternetConnection
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func shouldQueueRequest(endpoint: APIEndpoint, error: Error) -> Bool {
        // Only queue certain types of requests
        switch endpoint.method {
        case .POST, .PUT, .PATCH, .DELETE:
            // Queue write operations
            return true
        case .GET:
            // Don't queue read operations by default
            return false
        default:
            return false
        }
    }
    
    private func queueRequestForLater(
        endpoint: APIEndpoint,
        queue: OfflineRequestQueue,
        priority: OfflineRequest.QueuePriority
    ) async {
        let offlineRequest = OfflineRequest(
            id: UUID().uuidString,
            endpoint: endpoint,
            timestamp: Date(),
            priority: priority,
            retryCount: 0,
            maxRetries: 3,
            requestData: nil, // TODO: Serialize request data
            expiresAt: Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        )
        
        await queue.enqueue(offlineRequest)
        Logger.info("📦 OfflineQueue: Queued request for later - \(endpoint.path)")
    }
}

// MARK: - APIEndpoint Offline Configuration
extension APIEndpoint {
    /// Whether this endpoint should be queued when offline
    var shouldQueueWhenOffline: Bool {
        switch method {
        case .POST, .PUT, .PATCH, .DELETE:
            // Queue write operations
            return !path.contains("realtime") && !path.contains("live")
        case .GET:
            // Generally don't queue read operations
            return false
        default:
            return false
        }
    }
    
    /// Priority for offline queue
    var offlineQueuePriority: OfflineRequest.QueuePriority {
        if path.contains("auth") || path.contains("login") {
            return .critical
        } else if path.contains("user") || path.contains("profile") {
            return .high
        } else {
            return .normal
        }
    }
    
    /// How long the request should remain in queue before expiring
    var offlineExpiration: TimeInterval {
        if path.contains("auth") {
            return 5 * 60 // 5 minutes for auth
        } else if method == .POST {
            return 24 * 60 * 60 // 24 hours for posts
        } else {
            return 12 * 60 * 60 // 12 hours default
        }
    }
}

// MARK: - Debug Support
#if DEBUG
extension OfflineRequestQueue {
    
    func printQueueStatus() async {
        let statistics = await getStatistics()
        let requests = await getQueuedRequests()
        
        print("""
        
        📦 ===== Offline Request Queue Status =====
        
        📊 STATISTICS:
        • Queue Size: \(statistics.currentQueueSize)
        • Total Queued: \(statistics.totalQueued)
        • Success Rate: \(String(format: "%.1f", statistics.successRate * 100))%
        • Oldest Request: \(String(format: "%.1f", statistics.oldestRequestAge))s ago
        • Avg Processing: \(String(format: "%.3f", statistics.averageProcessingTime))s
        
        📋 QUEUED REQUESTS:
        """)
        
        for request in requests.prefix(10) {
            let age = Date().timeIntervalSince(request.timestamp)
            print("  • \(request.priority.description): \(request.endpoint.path) (\(String(format: "%.0f", age))s ago)")
        }
        
        if requests.count > 10 {
            print("  ... and \(requests.count - 10) more")
        }
        
        print("========================================\n")
    }
}
#endif 