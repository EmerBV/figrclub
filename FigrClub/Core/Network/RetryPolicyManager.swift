//
//  RetryPolicyManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Retry Policy Types
enum RetryPolicyType {
    case none
    case fixed(delay: TimeInterval, maxAttempts: Int)
    case exponentialBackoff(baseDelay: TimeInterval, maxAttempts: Int, maxDelay: TimeInterval)
    case linearBackoff(baseDelay: TimeInterval, maxAttempts: Int)
    case adaptive(initialDelay: TimeInterval, maxAttempts: Int)
}

// MARK: - Retry Context
struct RetryContext {
    let attemptNumber: Int
    let totalAttempts: Int
    let lastError: Error
    let endpoint: String
    let method: String
    let startTime: Date
    
    var totalDuration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var isLastAttempt: Bool {
        attemptNumber >= totalAttempts
    }
}

// MARK: - Retry Decision
enum RetryDecision {
    case retry(after: TimeInterval)
    case stop(reason: StopReason)
    
    enum StopReason {
        case maxAttemptsReached
        case nonRetryableError
        case maxTimeExceeded
        case userCancellation
    }
}

// MARK: - Retry Policy Protocol
protocol RetryPolicyProtocol: Sendable {
    func shouldRetry(context: RetryContext) async -> RetryDecision
    func calculateDelay(for attemptNumber: Int) async -> TimeInterval
    func isRetryableError(_ error: Error) async -> Bool
}

// MARK: - Retry Policy Manager
actor RetryPolicyManager: RetryPolicyProtocol {
    
    // MARK: - Properties
    private let policyType: RetryPolicyType
    private let jitterEnabled: Bool
    private let maxTotalTime: TimeInterval
    private var retryStatistics: [String: RetryStatistics] = [:]
    
    // MARK: - Retry Statistics
    struct RetryStatistics {
        var totalRetries: Int = 0
        var successfulRetries: Int = 0
        var failedRetries: Int = 0
        var averageDelay: TimeInterval = 0
        var lastRetryTime: Date?
        
        var successRate: Double {
            totalRetries > 0 ? Double(successfulRetries) / Double(totalRetries) : 0
        }
        
        mutating func recordRetry(delay: TimeInterval, success: Bool) {
            totalRetries += 1
            if success {
                successfulRetries += 1
            } else {
                failedRetries += 1
            }
            
            // Update average delay
            averageDelay = (averageDelay * Double(totalRetries - 1) + delay) / Double(totalRetries)
            lastRetryTime = Date()
        }
    }
    
    // MARK: - Initialization
    init(
        policyType: RetryPolicyType = .exponentialBackoff(baseDelay: 1.0, maxAttempts: 3, maxDelay: 30.0),
        jitterEnabled: Bool = true,
        maxTotalTime: TimeInterval = 60.0
    ) {
        self.policyType = policyType
        self.jitterEnabled = jitterEnabled
        self.maxTotalTime = maxTotalTime
    }
    
    // MARK: - Retry Decision Logic
    
    func shouldRetry(context: RetryContext) async -> RetryDecision {
        // Check if max time exceeded
        if context.totalDuration > maxTotalTime {
            Logger.warning("🔄 Retry: Max total time exceeded (\(context.totalDuration)s)")
            return .stop(reason: .maxTimeExceeded)
        }
        
        // Check if last attempt
        if context.isLastAttempt {
            Logger.debug("🔄 Retry: Max attempts reached (\(context.attemptNumber)/\(context.totalAttempts))")
            return .stop(reason: .maxAttemptsReached)
        }
        
        // Check if error is retryable
        guard isRetryableError(context.lastError) else {
            Logger.debug("🔄 Retry: Non-retryable error - \(context.lastError.localizedDescription)")
            return .stop(reason: .nonRetryableError)
        }
        
        // Calculate delay for next attempt
        let delay = calculateDelay(for: context.attemptNumber)
        
        // Record retry statistics
        let endpointKey = "\(context.method) \(context.endpoint)"
        await recordRetryAttempt(for: endpointKey, delay: delay)
        
        Logger.debug("🔄 Retry: Attempt \(context.attemptNumber + 1)/\(context.totalAttempts) in \(String(format: "%.2f", delay))s")
        
        return .retry(after: delay)
    }
    
    func calculateDelay(for attemptNumber: Int) -> TimeInterval {
        let baseDelay: TimeInterval
        
        switch policyType {
        case .none:
            return 0
            
        case .fixed(let delay, _):
            baseDelay = delay
            
        case .exponentialBackoff(let base, _, let maxDelay):
            // Exponential backoff: delay = base * (2^attempt)
            let exponentialDelay = base * pow(2.0, Double(attemptNumber))
            baseDelay = min(exponentialDelay, maxDelay)
            
        case .linearBackoff(let base, _):
            // Linear backoff: delay = base * attempt
            baseDelay = base * Double(attemptNumber + 1)
            
        case .adaptive(let initialDelay, _):
            // Adaptive backoff based on historical performance
            baseDelay = calculateAdaptiveDelay(initialDelay: initialDelay, attemptNumber: attemptNumber)
        }
        
        // Add jitter if enabled (±25% randomization)
        if jitterEnabled {
            let jitterRange = baseDelay * 0.25
            let jitter = Double.random(in: -jitterRange...jitterRange)
            return max(0.1, baseDelay + jitter)
        }
        
        return baseDelay
    }
    
    func isRetryableError(_ error: Error) -> Bool {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .timeout, .noInternetConnection:
                return true
            case .serverError:
                return true
            case .rateLimited:
                return true
            case .unauthorized, .forbidden, .notFound, .badRequest:
                return false // Don't retry client errors
            case .invalidURL, .invalidResponse, .decodingError:
                return false // Don't retry structural errors
            case .maintenance:
                return true // Retry maintenance errors
            case .unknown:
                return true // Retry unknown errors (could be transient)
            }
        }
        
        // Check for URLError cases
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost:
                return true
            case .notConnectedToInternet, .dataNotAllowed:
                return true
            case .badURL, .unsupportedURL:
                return false
            default:
                return true // Err on the side of retrying for URLErrors
            }
        }
        
        // Retry other errors by default
        return true
    }
    
    // MARK: - Statistics and Monitoring
    
    func getRetryStatistics() async -> [String: RetryStatistics] {
        return retryStatistics
    }
    
    func getRetryStatistics(for endpoint: String) async -> RetryStatistics? {
        return retryStatistics[endpoint]
    }
    
    func resetStatistics() async {
        retryStatistics.removeAll()
        Logger.debug("🔄 Retry: Statistics reset")
    }
    
    // MARK: - Private Methods
    
    private func calculateAdaptiveDelay(initialDelay: TimeInterval, attemptNumber: Int) -> TimeInterval {
        // Adaptive delay based on recent success rates
        let baseDelay = initialDelay * Double(attemptNumber + 1)
        
        // Could enhance this with historical data
        // For now, use a simple adaptive approach
        return baseDelay
    }
    
    private func recordRetryAttempt(for endpoint: String, delay: TimeInterval) async {
        if retryStatistics[endpoint] == nil {
            retryStatistics[endpoint] = RetryStatistics()
        }
        // The success/failure will be recorded later when we know the outcome
    }
    
    func recordRetryOutcome(for endpoint: String, success: Bool, delay: TimeInterval) async {
        if retryStatistics[endpoint] == nil {
            retryStatistics[endpoint] = RetryStatistics()
        }
        retryStatistics[endpoint]?.recordRetry(delay: delay, success: success)
    }
}

// MARK: - Retry Policy Factory
struct RetryPolicyFactory {
    
    static func createPolicy(for endpoint: APIEndpoint) -> RetryPolicyManager {
        let policy: RetryPolicyType
        
        switch endpoint.method {
        case .GET:
            // GET requests are idempotent - more aggressive retry
            policy = .exponentialBackoff(baseDelay: 1.0, maxAttempts: 4, maxDelay: 16.0)
            
        case .POST:
            if endpoint.isIdempotent {
                // Idempotent POST requests
                policy = .exponentialBackoff(baseDelay: 2.0, maxAttempts: 3, maxDelay: 10.0)
            } else {
                // Non-idempotent POST requests - be more careful
                policy = .fixed(delay: 3.0, maxAttempts: 2)
            }
            
        case .PUT, .PATCH:
            // Usually idempotent - moderate retry
            policy = .linearBackoff(baseDelay: 2.0, maxAttempts: 3)
            
        case .DELETE:
            // DELETE is usually idempotent
            policy = .exponentialBackoff(baseDelay: 1.5, maxAttempts: 3, maxDelay: 8.0)
            
        default:
            // Conservative default
            policy = .fixed(delay: 2.0, maxAttempts: 2)
        }
        
        return RetryPolicyManager(
            policyType: policy,
            jitterEnabled: true,
            maxTotalTime: 60.0
        )
    }
    
    static func createAggressivePolicy() -> RetryPolicyManager {
        return RetryPolicyManager(
            policyType: .exponentialBackoff(baseDelay: 0.5, maxAttempts: 5, maxDelay: 30.0),
            jitterEnabled: true,
            maxTotalTime: 90.0
        )
    }
    
    static func createConservativePolicy() -> RetryPolicyManager {
        return RetryPolicyManager(
            policyType: .fixed(delay: 5.0, maxAttempts: 2),
            jitterEnabled: false,
            maxTotalTime: 30.0
        )
    }
}

// MARK: - Enhanced Network Dispatcher with Retry Support
extension NetworkDispatcher {
    
    /// Dispatch with intelligent retry support
    func dispatchWithRetry<T: Codable>(
        _ endpoint: APIEndpoint,
        retryPolicy: RetryPolicyManager? = nil
    ) async throws -> T {
        let policy = retryPolicy ?? RetryPolicyFactory.createPolicy(for: endpoint)
        let maxAttempts = getMaxAttempts(for: policy)
        let startTime = Date()
        
        var lastError: Error = NetworkError.unknown(NSError())
        
        for attempt in 0..<maxAttempts {
            do {
                let result: T = try await dispatch(endpoint)
                
                // Record successful retry outcome if this wasn't the first attempt
                if attempt > 0 {
                    let endpointKey = "\(endpoint.method.rawValue) \(endpoint.path)"
                    await policy.recordRetryOutcome(for: endpointKey, success: true, delay: 0)
                    Logger.debug("✅ Retry: Successful after \(attempt + 1) attempts")
                }
                
                return result
                
            } catch {
                lastError = error
                
                let context = RetryContext(
                    attemptNumber: attempt,
                    totalAttempts: maxAttempts,
                    lastError: error,
                    endpoint: endpoint.path,
                    method: endpoint.method.rawValue,
                    startTime: startTime
                )
                
                let decision = await policy.shouldRetry(context: context)
                
                switch decision {
                case .retry(let delay):
                    Logger.warning("⚠️ Retry: Attempt \(attempt + 1) failed, retrying in \(String(format: "%.2f", delay))s - \(error.localizedDescription)")
                    
                    // Wait for the calculated delay
                    try await Task.sleep(for: .seconds(delay))
                    
                case .stop(let reason):
                    Logger.error("❌ Retry: Stopping retries - \(reason)")
                    
                    // Record failed retry outcome
                    let endpointKey = "\(endpoint.method.rawValue) \(endpoint.path)"
                    await policy.recordRetryOutcome(for: endpointKey, success: false, delay: 0)
                    
                    throw lastError
                }
            }
        }
        
        throw lastError
    }
    
    // MARK: - Private Helpers
    
    private func getMaxAttempts(for retryPolicy: RetryPolicyManager) -> Int {
        // This would need to be exposed from RetryPolicyManager or calculated
        return 3 // Default fallback
    }
}

// MARK: - APIEndpoint Retry Configuration
extension APIEndpoint {
    /// Whether this endpoint's operations are idempotent
    var isIdempotent: Bool {
        switch method {
        case .GET, .PUT, .DELETE, .HEAD, .OPTIONS:
            return true
        case .POST:
            // POST is generally not idempotent, but some specific endpoints might be
            return path.contains("search") || path.contains("query")
        case .PATCH:
            // PATCH can be idempotent depending on implementation
            return false
        }
    }
    
    /// Custom retry policy for this endpoint
    var customRetryPolicy: RetryPolicyType {
        // Auth endpoints - be more aggressive since they're critical
        if path.contains("auth") || path.contains("login") {
            return .exponentialBackoff(baseDelay: 0.5, maxAttempts: 4, maxDelay: 8.0)
        }
        
        // User data endpoints - moderate retry
        if path.contains("user") || path.contains("profile") {
            return .linearBackoff(baseDelay: 1.0, maxAttempts: 3)
        }
        
        // Real-time endpoints - fail fast
        if path.contains("realtime") || path.contains("live") {
            return .fixed(delay: 1.0, maxAttempts: 1)
        }
        
        // Default policy
        return .exponentialBackoff(baseDelay: 1.0, maxAttempts: 3, maxDelay: 16.0)
    }
}

// MARK: - Debug Support
#if DEBUG
extension RetryPolicyManager {
    
    func printRetryStatistics() async {
        let stats = await getRetryStatistics()
        
        print("""
        
        🔄 ===== Retry Policy Statistics =====
        
        📊 ENDPOINT PERFORMANCE:
        """)
        
        for (endpoint, statistics) in stats.sorted(by: { $0.value.totalRetries > $1.value.totalRetries }) {
            print("""
            • \(endpoint):
              - Total Retries: \(statistics.totalRetries)
              - Success Rate: \(String(format: "%.1f", statistics.successRate * 100))%
              - Avg Delay: \(String(format: "%.2f", statistics.averageDelay))s
              - Last Retry: \(statistics.lastRetryTime?.timeIntervalSinceNow ?? 0)s ago
            """)
        }
        
        print("======================================\n")
    }
}
#endif 