//
//  BackgroundRefreshManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import BackgroundTasks

// MARK: - Background Refresh Configuration
struct BackgroundRefreshConfig {
    let refreshInterval: TimeInterval      // How often to refresh
    let staleThreshold: TimeInterval       // When data is considered stale
    let maxConcurrentRefreshes: Int        // Max parallel refresh operations
    let retryPolicy: BackgroundRetryPolicy // Retry configuration
    let enabledEndpoints: Set<String>      // Which endpoints to refresh
    
    enum BackgroundRetryPolicy {
        case none
        case simple(maxAttempts: Int)
        case exponential(maxAttempts: Int, baseDelay: TimeInterval)
    }
    
    static let `default` = BackgroundRefreshConfig(
        refreshInterval: 300,      // 5 minutes
        staleThreshold: 180,       // 3 minutes
        maxConcurrentRefreshes: 3,
        retryPolicy: .simple(maxAttempts: 2),
        enabledEndpoints: []
    )
    
    static let aggressive = BackgroundRefreshConfig(
        refreshInterval: 60,       // 1 minute
        staleThreshold: 30,        // 30 seconds
        maxConcurrentRefreshes: 5,
        retryPolicy: .exponential(maxAttempts: 3, baseDelay: 1.0),
        enabledEndpoints: []
    )
}

// MARK: - Background Refresh State
enum BackgroundRefreshState {
    case idle
    case refreshing
    case scheduled
    case paused
}

// MARK: - Background Refresh Entry
struct BackgroundRefreshEntry {
    let cacheKey: String
    let endpoint: APIEndpoint
    let lastRefresh: Date
    let priority: RefreshPriority
    let stalenessScore: Double  // 0.0 = fresh, 1.0 = very stale
    
    enum RefreshPriority: Int, CaseIterable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        var weight: Double {
            switch self {
            case .low: return 1.0
            case .normal: return 2.0
            case .high: return 3.0
            case .critical: return 5.0
            }
        }
    }
    
    var needsRefresh: Bool {
        stalenessScore > 0.5 // Refresh when 50% stale
    }
    
    var refreshScore: Double {
        return stalenessScore * priority.weight
    }
}

// MARK: - Background Refresh Statistics
struct BackgroundRefreshStatistics {
    var totalRefreshes: Int = 0
    var successfulRefreshes: Int = 0
    var failedRefreshes: Int = 0
    var backgroundRefreshes: Int = 0
    var foregroundRefreshes: Int = 0
    var dataSaved: Int = 0  // Bytes saved by using stale data
    
    var successRate: Double {
        totalRefreshes > 0 ? Double(successfulRefreshes) / Double(totalRefreshes) : 0.0
    }
    
    mutating func recordRefresh(success: Bool, inBackground: Bool, dataSaved: Int = 0) {
        totalRefreshes += 1
        
        if success {
            successfulRefreshes += 1
        } else {
            failedRefreshes += 1
        }
        
        if inBackground {
            backgroundRefreshes += 1
        } else {
            foregroundRefreshes += 1
        }
        
        self.dataSaved += dataSaved
    }
}

// MARK: - Background Refresh Manager Protocol
protocol BackgroundRefreshManagerProtocol: Sendable {
    func scheduleRefresh(for cacheKey: String, endpoint: APIEndpoint, priority: BackgroundRefreshEntry.RefreshPriority) async
    func performBackgroundRefresh() async
    func updateStaleness(for cacheKey: String, age: TimeInterval, maxAge: TimeInterval) async
    func pauseBackgroundRefresh() async
    func resumeBackgroundRefresh() async
    func getStatistics() async -> BackgroundRefreshStatistics
}

// MARK: - Background Refresh Manager
actor BackgroundRefreshManager: BackgroundRefreshManagerProtocol {
    
    // MARK: - Properties
    private var refreshEntries: [String: BackgroundRefreshEntry] = [:]
    private var config: BackgroundRefreshConfig
    private var state: BackgroundRefreshState = .idle
    private var statistics = BackgroundRefreshStatistics()
    private let cache: NetworkCacheProtocol
    private let networkDispatcher: NetworkDispatcher
    private var refreshTimer: Timer?
    private var activeRefreshTasks: Set<String> = []
    
    // MARK: - Initialization
    init(
        config: BackgroundRefreshConfig = .default,
        cache: NetworkCacheProtocol,
        networkDispatcher: NetworkDispatcher
    ) {
        self.config = config
        self.cache = cache
        self.networkDispatcher = networkDispatcher
        
        Task {
            await startBackgroundRefresh()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func scheduleRefresh(
        for cacheKey: String,
        endpoint: APIEndpoint,
        priority: BackgroundRefreshEntry.RefreshPriority = .normal
    ) async {
        // Check if endpoint is enabled for background refresh
        guard config.enabledEndpoints.isEmpty || config.enabledEndpoints.contains(endpoint.path) else {
            return
        }
        
        let entry = BackgroundRefreshEntry(
            cacheKey: cacheKey,
            endpoint: endpoint,
            lastRefresh: Date(),
            priority: priority,
            stalenessScore: 0.0
        )
        
        refreshEntries[cacheKey] = entry
        Logger.debug("🔄 BackgroundRefresh: Scheduled refresh for \(endpoint.path)")
    }
    
    func performBackgroundRefresh() async {
        guard state != .paused && state != .refreshing else {
            return
        }
        
        state = .refreshing
        defer { state = .idle }
        
        Logger.debug("🔄 BackgroundRefresh: Starting background refresh cycle")
        
        // Get entries that need refresh, sorted by priority
        let entriesToRefresh = refreshEntries.values
            .filter { $0.needsRefresh }
            .sorted { $0.refreshScore > $1.refreshScore }
            .prefix(config.maxConcurrentRefreshes)
        
        guard !entriesToRefresh.isEmpty else {
            Logger.debug("🔄 BackgroundRefresh: No entries need refresh")
            return
        }
        
        // Perform refreshes concurrently
        await withTaskGroup(of: Void.self) { group in
            for entry in entriesToRefresh {
                group.addTask {
                    await self.refreshEntry(entry)
                }
            }
        }
        
        Logger.info("🔄 BackgroundRefresh: Completed refresh cycle - \(entriesToRefresh.count) entries processed")
    }
    
    func updateStaleness(for cacheKey: String, age: TimeInterval, maxAge: TimeInterval) async {
        guard var entry = refreshEntries[cacheKey] else { return }
        
        // Calculate staleness score (0.0 = fresh, 1.0 = expired)
        let normalizedAge = min(age / maxAge, 1.0)
        let staleness = max(0.0, min(1.0, normalizedAge))
        
        // Update entry with new staleness
        let updatedEntry = BackgroundRefreshEntry(
            cacheKey: entry.cacheKey,
            endpoint: entry.endpoint,
            lastRefresh: entry.lastRefresh,
            priority: entry.priority,
            stalenessScore: staleness
        )
        
        refreshEntries[cacheKey] = updatedEntry
        
        // Trigger immediate refresh if critically stale
        if staleness > 0.8 && entry.priority == .critical {
            Task {
                await refreshEntry(updatedEntry)
            }
        }
    }
    
    func pauseBackgroundRefresh() async {
        state = .paused
        refreshTimer?.invalidate()
        Logger.info("⏸️ BackgroundRefresh: Paused")
    }
    
    func resumeBackgroundRefresh() async {
        state = .idle
        await startBackgroundRefresh()
        Logger.info("▶️ BackgroundRefresh: Resumed")
    }
    
    func getStatistics() async -> BackgroundRefreshStatistics {
        return statistics
    }
    
    // MARK: - Configuration
    
    func updateConfig(_ newConfig: BackgroundRefreshConfig) async {
        config = newConfig
        
        // Restart with new configuration
        await pauseBackgroundRefresh()
        await resumeBackgroundRefresh()
        
        Logger.debug("⚙️ BackgroundRefresh: Updated configuration")
    }
    
    func enableEndpoint(_ endpoint: String) async {
        config = BackgroundRefreshConfig(
            refreshInterval: config.refreshInterval,
            staleThreshold: config.staleThreshold,
            maxConcurrentRefreshes: config.maxConcurrentRefreshes,
            retryPolicy: config.retryPolicy,
            enabledEndpoints: config.enabledEndpoints.union([endpoint])
        )
        
        Logger.debug("✅ BackgroundRefresh: Enabled refresh for \(endpoint)")
    }
    
    func disableEndpoint(_ endpoint: String) async {
        config = BackgroundRefreshConfig(
            refreshInterval: config.refreshInterval,
            staleThreshold: config.staleThreshold,
            maxConcurrentRefreshes: config.maxConcurrentRefreshes,
            retryPolicy: config.retryPolicy,
            enabledEndpoints: config.enabledEndpoints.subtracting([endpoint])
        )
        
        // Remove any scheduled refreshes for this endpoint
        refreshEntries = refreshEntries.filter { $0.value.endpoint.path != endpoint }
        
        Logger.debug("❌ BackgroundRefresh: Disabled refresh for \(endpoint)")
    }
    
    // MARK: - Private Methods
    
    private func startBackgroundRefresh() async {
        guard state != .paused else { return }
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: config.refreshInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performBackgroundRefresh()
            }
        }
        
        state = .scheduled
        Logger.debug("🔄 BackgroundRefresh: Started with interval \(config.refreshInterval)s")
    }
    
    private func refreshEntry(_ entry: BackgroundRefreshEntry) async {
        let cacheKey = entry.cacheKey
        
        // Prevent concurrent refreshes of the same entry
        guard !activeRefreshTasks.contains(cacheKey) else {
            return
        }
        
        activeRefreshTasks.insert(cacheKey)
        defer { activeRefreshTasks.remove(cacheKey) }
        
        let startTime = Date()
        
        do {
            // Perform the background refresh
            let data: Data = try await networkDispatcher.dispatchData(entry.endpoint)
            
            // Update cache with fresh data
            await cache.store(
                data,
                for: cacheKey,
                with: .networkFirst,
                etag: nil, // TODO: Extract ETag from response
                maxAge: entry.endpoint.cacheMaxAge
            )
            
            // Update entry with new refresh time
            let updatedEntry = BackgroundRefreshEntry(
                cacheKey: entry.cacheKey,
                endpoint: entry.endpoint,
                lastRefresh: Date(),
                priority: entry.priority,
                stalenessScore: 0.0 // Fresh data
            )
            refreshEntries[cacheKey] = updatedEntry
            
            // Record statistics
            let processingTime = Date().timeIntervalSince(startTime)
            statistics.recordRefresh(success: true, inBackground: true)
            
            Logger.debug("✅ BackgroundRefresh: Refreshed \(entry.endpoint.path) in \(String(format: "%.3f", processingTime))s")
            
        } catch {
            // Handle refresh failure
            await handleRefreshFailure(entry, error: error)
            statistics.recordRefresh(success: false, inBackground: true)
            
            Logger.warning("❌ BackgroundRefresh: Failed to refresh \(entry.endpoint.path) - \(error.localizedDescription)")
        }
    }
    
    private func handleRefreshFailure(_ entry: BackgroundRefreshEntry, error: Error) async {
        switch config.retryPolicy {
        case .none:
            // Don't retry
            break
            
        case .simple(let maxAttempts):
            // Simple retry logic
            if entry.lastRefresh.timeIntervalSinceNow > -60 { // Don't retry if last attempt was recent
                await scheduleRetry(entry, delay: 30.0)
            }
            
        case .exponential(let maxAttempts, let baseDelay):
            // Exponential backoff retry
            let attempt = 1 // Would need to track attempt count
            let delay = baseDelay * pow(2.0, Double(attempt - 1))
            await scheduleRetry(entry, delay: min(delay, 300.0)) // Max 5 minutes
        }
    }
    
    private func scheduleRetry(_ entry: BackgroundRefreshEntry, delay: TimeInterval) async {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            await refreshEntry(entry)
        }
    }
}

// MARK: - Enhanced Network Cache with Background Refresh Integration
extension NetworkCache {
    
    /// Enhanced retrieve with background refresh integration
    func retrieveWithBackgroundRefresh(
        for url: String,
        policy: CachePolicy,
        backgroundRefresh: BackgroundRefreshManager? = nil
    ) async -> CacheEntry? {
        let entry = await retrieve(for: url, policy: policy)
        
        // Check if we should schedule background refresh
        if let entry = entry,
           let backgroundRefresh = backgroundRefresh,
           policy == .staleWhileRevalidate {
            
            // Calculate how stale the data is
            let age = entry.age
            let maxAge = entry.maxAge
            
            // Update staleness in background refresh manager
            // This would require knowing the endpoint, which isn't available here
            // In a real implementation, you'd pass the endpoint or store it in the cache entry
        }
        
        return entry
    }
}

// MARK: - Background Task Integration (iOS)
extension BackgroundRefreshManager {
    
    /// Register background app refresh task
    func registerBackgroundTasks() {
        #if os(iOS)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.figrclub.background-refresh",
            using: nil
        ) { task in
            Task {
                await self.handleBackgroundRefreshTask(task as! BGAppRefreshTask)
            }
        }
        #endif
    }
    
    /// Handle background refresh task
    private func handleBackgroundRefreshTask(_ task: BGAppRefreshTask) async {
        #if os(iOS)
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        await performBackgroundRefresh()
        task.setTaskCompleted(success: true)
        
        // Schedule next background refresh
        scheduleNextBackgroundRefresh()
        #endif
    }
    
    /// Schedule next background refresh
    private func scheduleNextBackgroundRefresh() {
        #if os(iOS)
        let request = BGAppRefreshTaskRequest(identifier: "com.figrclub.background-refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: config.refreshInterval)
        
        try? BGTaskScheduler.shared.submit(request)
        #endif
    }
}

// MARK: - Debug Support
#if DEBUG
extension BackgroundRefreshManager {
    
    func printRefreshStatus() async {
        let statistics = await getStatistics()
        let entriesCount = refreshEntries.count
        let staleEntries = refreshEntries.values.filter { $0.needsRefresh }.count
        
        print("""
        
        🔄 ===== Background Refresh Status =====
        
        📊 STATISTICS:
        • Total Refreshes: \(statistics.totalRefreshes)
        • Success Rate: \(String(format: "%.1f", statistics.successRate * 100))%
        • Background: \(statistics.backgroundRefreshes)
        • Foreground: \(statistics.foregroundRefreshes)
        • Data Saved: \(formatBytes(statistics.dataSaved))
        
        📋 REFRESH QUEUE:
        • Total Entries: \(entriesCount)
        • Stale Entries: \(staleEntries)
        • State: \(state)
        • Interval: \(config.refreshInterval)s
        
        =====================================\n
        """)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
#endif 