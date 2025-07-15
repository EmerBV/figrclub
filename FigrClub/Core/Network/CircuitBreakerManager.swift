//
//  CircuitBreakerManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Circuit Breaker States
enum CircuitBreakerState {
    case closed    // Normal operation
    case open      // Circuit is open, failing fast
    case halfOpen  // Testing if service has recovered
}

// MARK: - Circuit Breaker Configuration
struct CircuitBreakerConfig {
    let failureThreshold: Int          // Number of failures before opening
    let recoveryTimeout: TimeInterval  // Time to wait before trying half-open
    let successThreshold: Int          // Successes needed in half-open to close
    let windowSize: TimeInterval       // Time window for failure counting
    let minimumRequests: Int           // Minimum requests needed to trigger evaluation
    
    static let `default` = CircuitBreakerConfig(
        failureThreshold: 5,
        recoveryTimeout: 30.0,
        successThreshold: 3,
        windowSize: 60.0,
        minimumRequests: 10
    )
    
    static let aggressive = CircuitBreakerConfig(
        failureThreshold: 3,
        recoveryTimeout: 15.0,
        successThreshold: 2,
        windowSize: 30.0,
        minimumRequests: 5
    )
    
    static let conservative = CircuitBreakerConfig(
        failureThreshold: 10,
        recoveryTimeout: 60.0,
        successThreshold: 5,
        windowSize: 120.0,
        minimumRequests: 20
    )
}

// MARK: - Circuit Breaker Metrics
struct CircuitBreakerMetrics {
    var totalRequests: Int = 0
    var failureCount: Int = 0
    var successCount: Int = 0
    var timeouts: Int = 0
    var lastFailureTime: Date?
    var lastSuccessTime: Date?
    var currentState: CircuitBreakerState = .closed
    var stateChangeTime: Date = Date()
    
    var failureRate: Double {
        totalRequests > 0 ? Double(failureCount) / Double(totalRequests) : 0.0
    }
    
    var successRate: Double {
        totalRequests > 0 ? Double(successCount) / Double(totalRequests) : 0.0
    }
    
    mutating func recordSuccess() {
        totalRequests += 1
        successCount += 1
        lastSuccessTime = Date()
    }
    
    mutating func recordFailure() {
        totalRequests += 1
        failureCount += 1
        lastFailureTime = Date()
    }
    
    mutating func recordTimeout() {
        timeouts += 1
        recordFailure()
    }
    
    mutating func reset() {
        totalRequests = 0
        failureCount = 0
        successCount = 0
        timeouts = 0
        lastFailureTime = nil
        lastSuccessTime = nil
    }
    
    mutating func setState(_ newState: CircuitBreakerState) {
        if currentState != newState {
            currentState = newState
            stateChangeTime = Date()
        }
    }
}

// MARK: - Circuit Breaker Error
enum CircuitBreakerError: Error, LocalizedError {
    case circuitOpen(endpoint: String, retryAfter: TimeInterval)
    case halfOpenLimitExceeded(endpoint: String)
    
    var errorDescription: String? {
        switch self {
        case .circuitOpen(let endpoint, let retryAfter):
            return "Circuit breaker is open for \(endpoint). Retry after \(Int(retryAfter)) seconds."
        case .halfOpenLimitExceeded(let endpoint):
            return "Half-open circuit limit exceeded for \(endpoint)."
        }
    }
}

// MARK: - Circuit Breaker Protocol
protocol CircuitBreakerProtocol: Sendable {
    func execute<T>(_ operation: @Sendable () async throws -> T, for endpoint: String) async throws -> T
    func getState(for endpoint: String) async -> CircuitBreakerState
    func getMetrics(for endpoint: String) async -> CircuitBreakerMetrics?
    func reset(for endpoint: String) async
    func resetAll() async
}

// MARK: - Circuit Breaker Manager
actor CircuitBreakerManager: CircuitBreakerProtocol {
    
    // MARK: - Properties
    private var circuits: [String: CircuitBreakerMetrics] = [:]
    private var configs: [String: CircuitBreakerConfig] = [:]
    private var halfOpenRequests: [String: Int] = [:]
    private let defaultConfig: CircuitBreakerConfig
    
    // MARK: - Initialization
    init(defaultConfig: CircuitBreakerConfig = .default) {
        self.defaultConfig = defaultConfig
    }
    
    // MARK: - Public Methods
    
    /// Execute operation with circuit breaker protection
    func execute<T>(_ operation: @Sendable () async throws -> T, for endpoint: String) async throws -> T {
        let config = getConfig(for: endpoint)
        var metrics = getOrCreateMetrics(for: endpoint)
        
        // Check current state and decide action
        switch metrics.currentState {
        case .closed:
            return try await executeInClosedState(operation, endpoint: endpoint, config: config, metrics: &metrics)
            
        case .open:
            return try await executeInOpenState(operation, endpoint: endpoint, config: config, metrics: &metrics)
            
        case .halfOpen:
            return try await executeInHalfOpenState(operation, endpoint: endpoint, config: config, metrics: &metrics)
        }
    }
    
    /// Get current state for endpoint
    func getState(for endpoint: String) async -> CircuitBreakerState {
        return circuits[endpoint]?.currentState ?? .closed
    }
    
    /// Get metrics for endpoint
    func getMetrics(for endpoint: String) async -> CircuitBreakerMetrics? {
        return circuits[endpoint]
    }
    
    /// Reset circuit for specific endpoint
    func reset(for endpoint: String) async {
        if var metrics = circuits[endpoint] {
            metrics.reset()
            metrics.setState(.closed)
            circuits[endpoint] = metrics
            halfOpenRequests[endpoint] = 0
            
            Logger.info("🔄 CircuitBreaker: Reset circuit for \(endpoint)")
        }
    }
    
    /// Reset all circuits
    func resetAll() async {
        for endpoint in circuits.keys {
            await reset(for: endpoint)
        }
        Logger.info("🔄 CircuitBreaker: Reset all circuits")
    }
    
    /// Configure circuit breaker for specific endpoint
    func configure(endpoint: String, config: CircuitBreakerConfig) async {
        configs[endpoint] = config
        Logger.debug("⚙️ CircuitBreaker: Configured \(endpoint) with custom settings")
    }
    
    /// Get all circuit states
    func getAllStates() async -> [String: CircuitBreakerState] {
        return circuits.mapValues { $0.currentState }
    }
    
    /// Get circuit breaker health summary
    func getHealthSummary() async -> CircuitBreakerHealthSummary {
        let allCircuits = circuits
        let openCircuits = allCircuits.filter { $0.value.currentState == .open }
        let halfOpenCircuits = allCircuits.filter { $0.value.currentState == .halfOpen }
        
        return CircuitBreakerHealthSummary(
            totalCircuits: allCircuits.count,
            openCircuits: openCircuits.count,
            halfOpenCircuits: halfOpenCircuits.count,
            closedCircuits: allCircuits.count - openCircuits.count - halfOpenCircuits.count,
            averageFailureRate: calculateAverageFailureRate(circuits: allCircuits)
        )
    }
    
    // MARK: - Private State Execution Methods
    
    private func executeInClosedState<T>(
        _ operation: @Sendable () async throws -> T,
        endpoint: String,
        config: CircuitBreakerConfig,
        metrics: inout CircuitBreakerMetrics
    ) async throws -> T {
        do {
            let result = try await operation()
            
            // Record success
            metrics.recordSuccess()
            circuits[endpoint] = metrics
            
            return result
            
        } catch {
            // Record failure
            metrics.recordFailure()
            
            // Check if we should open the circuit
            if shouldOpenCircuit(metrics: metrics, config: config) {
                Logger.warning("🚨 CircuitBreaker: Opening circuit for \(endpoint) - \(metrics.failureCount) failures")
                metrics.setState(.open)
                
                // Record circuit breaker opened event in analytics
                await recordCircuitBreakerEvent(.circuitBreakerOpen, endpoint: endpoint)
            }
            
            circuits[endpoint] = metrics
            throw error
        }
    }
    
    private func executeInOpenState<T>(
        _ operation: @Sendable () async throws -> T,
        endpoint: String,
        config: CircuitBreakerConfig,
        metrics: inout CircuitBreakerMetrics
    ) async throws -> T {
        let timeSinceOpen = Date().timeIntervalSince(metrics.stateChangeTime)
        
        // Check if recovery timeout has passed
        if timeSinceOpen >= config.recoveryTimeout {
            Logger.info("🔄 CircuitBreaker: Attempting recovery for \(endpoint) - entering half-open state")
            metrics.setState(.halfOpen)
            halfOpenRequests[endpoint] = 0
            circuits[endpoint] = metrics
            
            // Try the operation in half-open state
            return try await executeInHalfOpenState(operation, endpoint: endpoint, config: config, metrics: &metrics)
        } else {
            // Circuit is still open, fail fast
            let retryAfter = config.recoveryTimeout - timeSinceOpen
            Logger.debug("⚡ CircuitBreaker: Circuit open for \(endpoint) - retry in \(String(format: "%.1f", retryAfter))s")
            throw CircuitBreakerError.circuitOpen(endpoint: endpoint, retryAfter: retryAfter)
        }
    }
    
    private func executeInHalfOpenState<T>(
        _ operation: @Sendable () async throws -> T,
        endpoint: String,
        config: CircuitBreakerConfig,
        metrics: inout CircuitBreakerMetrics
    ) async throws -> T {
        let currentHalfOpenRequests = halfOpenRequests[endpoint, default: 0]
        
        // Limit concurrent requests in half-open state
        if currentHalfOpenRequests >= config.successThreshold {
            throw CircuitBreakerError.halfOpenLimitExceeded(endpoint: endpoint)
        }
        
        halfOpenRequests[endpoint] = currentHalfOpenRequests + 1
        
        do {
            let result = try await operation()
            
            // Record success
            metrics.recordSuccess()
            
            // Check if we have enough successes to close the circuit
            if halfOpenRequests[endpoint, default: 0] >= config.successThreshold {
                Logger.info("✅ CircuitBreaker: Closing circuit for \(endpoint) - recovery successful")
                metrics.setState(.closed)
                metrics.reset() // Reset failure counts
                halfOpenRequests[endpoint] = 0
            }
            
            circuits[endpoint] = metrics
            return result
            
        } catch {
            // Single failure in half-open state opens the circuit again
            Logger.warning("❌ CircuitBreaker: Half-open test failed for \(endpoint) - reopening circuit")
            metrics.recordFailure()
            metrics.setState(.open)
            halfOpenRequests[endpoint] = 0
            circuits[endpoint] = metrics
            
            throw error
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getConfig(for endpoint: String) -> CircuitBreakerConfig {
        return configs[endpoint] ?? defaultConfig
    }
    
    private func getOrCreateMetrics(for endpoint: String) -> CircuitBreakerMetrics {
        if let existing = circuits[endpoint] {
            return existing
        }
        
        let newMetrics = CircuitBreakerMetrics()
        circuits[endpoint] = newMetrics
        return newMetrics
    }
    
    private func shouldOpenCircuit(metrics: CircuitBreakerMetrics, config: CircuitBreakerConfig) -> Bool {
        // Need minimum requests to evaluate
        guard metrics.totalRequests >= config.minimumRequests else {
            return false
        }
        
        // Check failure threshold
        return metrics.failureCount >= config.failureThreshold
    }
    
    private func calculateAverageFailureRate(circuits: [String: CircuitBreakerMetrics]) -> Double {
        guard !circuits.isEmpty else { return 0.0 }
        
        let totalFailureRate = circuits.values.reduce(0.0) { $0 + $1.failureRate }
        return totalFailureRate / Double(circuits.count)
    }
    
    private func recordCircuitBreakerEvent(_ event: AnalyticsEventType, endpoint: String) async {
        // This would integrate with the analytics service
        Logger.info("📊 CircuitBreaker: Recording event \(event) for \(endpoint)")
    }
}

// MARK: - Circuit Breaker Health Summary
struct CircuitBreakerHealthSummary {
    let totalCircuits: Int
    let openCircuits: Int
    let halfOpenCircuits: Int
    let closedCircuits: Int
    let averageFailureRate: Double
    
    var isHealthy: Bool {
        return openCircuits == 0 && averageFailureRate < 0.1
    }
    
    var healthScore: Double {
        guard totalCircuits > 0 else { return 1.0 }
        
        let openPenalty = Double(openCircuits) / Double(totalCircuits) * 0.5
        let halfOpenPenalty = Double(halfOpenCircuits) / Double(totalCircuits) * 0.2
        let failurePenalty = averageFailureRate * 0.3
        
        return max(0.0, 1.0 - openPenalty - halfOpenPenalty - failurePenalty)
    }
}

// MARK: - Circuit Breaker Interceptor
struct CircuitBreakerInterceptor: RequestInterceptor {
    private let circuitBreaker: CircuitBreakerManager
    
    init(circuitBreaker: CircuitBreakerManager) {
        self.circuitBreaker = circuitBreaker
    }
    
    func intercept(request: URLRequest, context: RequestContext) async throws -> URLRequest {
        let endpoint = request.url?.path ?? "unknown"
        
        // Check circuit breaker state before allowing request
        let state = await circuitBreaker.getState(for: endpoint)
        
        if state == .open {
            // Circuit is open, don't allow request
            throw CircuitBreakerError.circuitOpen(endpoint: endpoint, retryAfter: 30.0)
        }
        
        // Store endpoint in context for later use
        var mutableContext = context
        mutableContext.metadata["circuitBreakerEndpoint"] = endpoint
        
        return request
    }
}



// MARK: - APIEndpoint Circuit Breaker Configuration
extension APIEndpoint {
    /// Circuit breaker configuration for this endpoint
    var circuitBreakerConfig: CircuitBreakerConfig {
        // Critical auth endpoints - more aggressive protection
        if path.contains("auth") || path.contains("login") {
            return .aggressive
        }
        
        // Real-time endpoints - fail fast
        if path.contains("realtime") || path.contains("live") {
            return CircuitBreakerConfig(
                failureThreshold: 2,
                recoveryTimeout: 10.0,
                successThreshold: 1,
                windowSize: 30.0,
                minimumRequests: 3
            )
        }
        
        // User data endpoints - conservative approach
        if path.contains("user") || path.contains("profile") {
            return .conservative
        }
        
        // Default configuration
        return .default
    }
}

// MARK: - Debug and Monitoring Support
#if DEBUG
extension CircuitBreakerManager {
    
    func printCircuitBreakerStatus() async {
        let healthSummary = await getHealthSummary()
        let allStates = await getAllStates()
        
        print("""
        
        ⚡ ===== Circuit Breaker Status =====
        
        📊 HEALTH SUMMARY:
        • Total Circuits: \(healthSummary.totalCircuits)
        • Health Score: \(String(format: "%.1f", healthSummary.healthScore * 100))%
        • Open Circuits: \(healthSummary.openCircuits)
        • Half-Open Circuits: \(healthSummary.halfOpenCircuits)
        • Closed Circuits: \(healthSummary.closedCircuits)
        • Average Failure Rate: \(String(format: "%.1f", healthSummary.averageFailureRate * 100))%
        
        🔌 CIRCUIT STATES:
        """)
        
        for (endpoint, state) in allStates.sorted(by: { $0.key < $1.key }) {
            let stateIcon = state == .open ? "🔴" : (state == .halfOpen ? "🟡" : "🟢")
            print("  \(stateIcon) \(endpoint): \(state)")
        }
        
        print("===================================\n")
    }
}
#endif 