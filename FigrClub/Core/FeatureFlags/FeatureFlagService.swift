//
//  FeatureFlagService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import Combine

// MARK: - Feature Flag Service Protocol
protocol FeatureFlagServiceProtocol: Sendable {
    func fetchRemoteFlags() async throws -> [FeatureFlag]
    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool
    func getFeatureValue(_ key: FeatureFlagKey) async -> Int
    func getAllFlags() async -> [FeatureFlag]
    func refreshFlags() async throws
    func setupPeriodicRefresh()
    func stopPeriodicRefresh()
}

// MARK: - Feature Flag Service Implementation
final class FeatureFlagService: FeatureFlagServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let configuration: FeatureFlagConfiguration
    private let networkDispatcher: NetworkDispatcherProtocol
    private let storage: FeatureFlagStorageProtocol
    private let logger: Logger.Type
    private let queue = DispatchQueue(label: "com.figrclub.featureflags", qos: .userInitiated)
    
    // Cache interno
    private var cachedFlags: [String: FeatureFlag] = [:]
    private var lastFetchTime: Date?
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    init(
        configuration: FeatureFlagConfiguration,
        networkDispatcher: NetworkDispatcherProtocol,
        storage: FeatureFlagStorageProtocol,
        logger: Logger.Type = Logger.self
    ) {
        self.configuration = configuration
        self.networkDispatcher = networkDispatcher
        self.storage = storage
        self.logger = logger
        
        Task {
            await loadCachedFlags()
            await setupPeriodicRefresh()
        }
        
        logger.info("🚩 FeatureFlagService: Initialized with remote URL: \(configuration.remoteURL)")
    }
    
    // MARK: - Public Methods
    
    func fetchRemoteFlags() async throws -> [FeatureFlag] {
        guard let url = URL(string: configuration.remoteURL) else {
            throw FeatureFlagError.invalidURL
        }
        
        logger.debug("🚩 FeatureFlagService: Fetching flags from: \(url.absoluteString)")
        
        do {
            let request = URLRequest(url: url)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            guard !data.isEmpty else {
                throw FeatureFlagError.noDataReceived
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let response = try decoder.decode(FeatureFlagsResponse.self, from: data)
            let flags = response.toFeatureFlags()
            
            logger.info("✅ FeatureFlagService: Successfully fetched \(flags.count) flags")
            
            // Update cache
            await updateCache(with: flags)
            
            // Store locally if enabled
            if configuration.enableLocalStorage {
                try await storage.store(flags)
            }
            
            lastFetchTime = Date()
            
            return flags
            
        } catch let decodingError as DecodingError {
            logger.error("❌ FeatureFlagService: JSON parsing error: \(decodingError)")
            throw FeatureFlagError.parsingError(decodingError.localizedDescription)
        } catch {
            logger.error("❌ FeatureFlagService: Network error: \(error)")
            throw FeatureFlagError.networkError(error)
        }
    }
    
    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool {
        let value = await getFeatureValue(key)
        return value == 1
    }
    
    func getFeatureValue(_ key: FeatureFlagKey) async -> Int {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: key.defaultValue)
                    return
                }
                
                // Check cache first
                if let cachedFlag = self.cachedFlags[key.rawValue] {
                    self.logger.debug("🚩 FeatureFlagService: Using cached value for \(key.rawValue): \(cachedFlag.value)")
                    continuation.resume(returning: cachedFlag.value)
                    return
                }
                
                // Use fallback value
                let fallbackValue = self.configuration.fallbackFlags[key] ?? key.defaultValue
                self.logger.debug("🚩 FeatureFlagService: Using fallback value for \(key.rawValue): \(fallbackValue)")
                
                // Store fallback in cache
                let fallbackFlag = FeatureFlag(id: key.rawValue, value: fallbackValue)
                self.cachedFlags[key.rawValue] = fallbackFlag
                
                continuation.resume(returning: fallbackValue)
            }
        }
    }
    
    func getAllFlags() async -> [FeatureFlag] {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Return cached flags if available
                if !self.cachedFlags.isEmpty {
                    continuation.resume(returning: Array(self.cachedFlags.values))
                    return
                }
                
                // Try to load from storage
                if self.configuration.enableLocalStorage {
                    Task {
                        do {
                            let storedFlags = try await self.storage.loadFlags()
                            if !storedFlags.isEmpty {
                                await self.updateCache(with: storedFlags)
                                continuation.resume(returning: storedFlags)
                                return
                            }
                        } catch {
                            self.logger.warning("⚠️ FeatureFlagService: Failed to load flags from storage: \(error)")
                        }
                        
                        // Return fallback flags
                        let fallbackFlags = self.configuration.fallbackFlags.map { key, value in
                            FeatureFlag(id: key.rawValue, value: value)
                        }
                        continuation.resume(returning: fallbackFlags)
                    }
                } else {
                    // Return fallback flags
                    let fallbackFlags = self.configuration.fallbackFlags.map { key, value in
                        FeatureFlag(id: key.rawValue, value: value)
                    }
                    continuation.resume(returning: fallbackFlags)
                }
            }
        }
    }
    
    func refreshFlags() async throws {
        logger.info("🔄 FeatureFlagService: Refreshing flags...")
        
        do {
            let _ = try await fetchRemoteFlags()
            logger.info("✅ FeatureFlagService: Flags refreshed successfully")
        } catch {
            logger.error("❌ FeatureFlagService: Failed to refresh flags: \(error)")
            throw error
        }
    }
    
    func setupPeriodicRefresh() {
        guard configuration.enableBackgroundRefresh else {
            logger.debug("🚩 FeatureFlagService: Periodic refresh disabled")
            return
        }
        
        stopPeriodicRefresh()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: configuration.refreshInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performPeriodicRefresh()
            }
        }
        
        logger.info("⏰ FeatureFlagService: Periodic refresh setup with interval: \(configuration.refreshInterval)s")
    }
    
    func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        logger.debug("⏸️ FeatureFlagService: Periodic refresh stopped")
    }
    
    // MARK: - Private Methods
    
    func updateCache(with flags: [FeatureFlag]) async {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                for flag in flags {
                    self.cachedFlags[flag.id] = flag
                }
                continuation.resume()
            }
        }
    }
    
    private func loadCachedFlags() async {
        guard configuration.enableLocalStorage else { return }
        
        do {
            let storedFlags = try await storage.loadFlags()
            await updateCache(with: storedFlags)
            logger.debug("🚩 FeatureFlagService: Loaded \(storedFlags.count) flags from storage")
        } catch {
            logger.warning("⚠️ FeatureFlagService: Failed to load cached flags: \(error)")
        }
    }
    
    private func performPeriodicRefresh() async {
        do {
            let _ = try await fetchRemoteFlags()
            logger.debug("🔄 FeatureFlagService: Periodic refresh completed")
        } catch {
            logger.warning("⚠️ FeatureFlagService: Periodic refresh failed: \(error)")
        }
    }
}

#if DEBUG
/// Mock Feature Flag Service for testing
final class MockFeatureFlagService: FeatureFlagServiceProtocol, @unchecked Sendable {
    private var mockFlags: [String: FeatureFlag] = [:]
    
    // MARK: - FeatureFlagServiceProtocol Implementation
    
    func fetchRemoteFlags() async throws -> [FeatureFlag] {
        return Array(mockFlags.values)
    }
    
    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool {
        return mockFlags[key.rawValue]?.isEnabled ?? false
    }
    
    func getFeatureValue(_ key: FeatureFlagKey) async -> Int {
        return mockFlags[key.rawValue]?.value ?? key.defaultValue
    }
    
    func getAllFlags() async -> [FeatureFlag] {
        return Array(mockFlags.values)
    }
    
    func refreshFlags() async throws {
        // Mock implementation - simulate successful refresh
        // In real implementation this would fetch and update flags
    }
    
    func setupPeriodicRefresh() {
        // Mock implementation - do nothing
    }
    
    func stopPeriodicRefresh() {
        // Mock implementation - do nothing
    }
    
    // MARK: - Mock-specific methods
    
    func setMockFlag(_ key: FeatureFlagKey, value: Int) {
        mockFlags[key.rawValue] = FeatureFlag(id: key.rawValue, value: value)
    }
    
    func enableMockFlag(_ key: FeatureFlagKey) {
        setMockFlag(key, value: 1)
    }
    
    func disableMockFlag(_ key: FeatureFlagKey) {
        setMockFlag(key, value: 0)
    }
    
    func clearMockFlags() {
        mockFlags.removeAll()
    }
}
#endif
