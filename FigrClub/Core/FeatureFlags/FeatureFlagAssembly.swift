//
//  FeatureFlagAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import Swinject

// MARK: - Feature Flag Assembly
final class FeatureFlagAssembly: Assembly {
    func assemble(container: Container) {
        
        // MARK: - Configuration
        
        // Feature Flag Configuration
        container.register(FeatureFlagConfiguration.self) { _ in
            let appConfig = AppConfig.shared
            
            switch appConfig.environment {
            case .development:
                return FeatureFlagConfiguration.development
            case .staging:
                return FeatureFlagConfiguration.default
            case .production:
                return FeatureFlagConfiguration.default
            }
        }.inObjectScope(.container)
        
        // MARK: - Storage
        
        // Feature Flag Storage
        container.register(FeatureFlagStorageProtocol.self) { _ in
            return FeatureFlagStorage()
        }.inObjectScope(.container)
        
        // MARK: - Service
        
        // Feature Flag Service
        container.register(FeatureFlagServiceProtocol.self) { resolver in
            let configuration = resolver.resolve(FeatureFlagConfiguration.self)!
            let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
            let storage = resolver.resolve(FeatureFlagStorageProtocol.self)!
            
            return FeatureFlagService(
                configuration: configuration,
                networkDispatcher: networkDispatcher,
                storage: storage
            )
        }.inObjectScope(.container)
        
        // MARK: - Manager
        
        // Feature Flag Manager - Create on main actor
        container.register(FeatureFlagManagerProtocol.self) { resolver in
            let service = resolver.resolve(FeatureFlagServiceProtocol.self)!
            let configuration = resolver.resolve(FeatureFlagConfiguration.self)!
            
            // Create on main actor to avoid actor isolation issues
            return MainActor.assumeIsolated {
                return FeatureFlagManager(
                    service: service,
                    configuration: configuration
                )
            }
        }.inObjectScope(.container)
        
        // Register concrete type for @EnvironmentObject
        container.register(FeatureFlagManager.self) { resolver in
            // This will be resolved on main actor too
            return resolver.resolve(FeatureFlagManagerProtocol.self)! as! FeatureFlagManager
        }.inObjectScope(.container)
        
        Logger.info("🚩 FeatureFlagAssembly: All feature flag dependencies registered")
    }
}

// MARK: - Feature Flag Configuration Extension
extension FeatureFlagConfiguration {
    
    /// Get configuration based on current app environment
    static func forCurrentEnvironment() -> FeatureFlagConfiguration {
        let appConfig = AppConfig.shared
        
        switch appConfig.environment {
        case .development:
            return .development
        case .staging:
            return FeatureFlagConfiguration(
                remoteURL: "https://raw.githubusercontent.com/figrclub/feature-flags/staging/flags.json",
                fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
                refreshInterval: 180, // 3 minutos
                enableLocalStorage: true,
                enableBackgroundRefresh: true
            )
        case .production:
            return .default
        }
    }
    
    /// Custom configuration with specific URL
    static func custom(
        remoteURL: String,
        refreshInterval: TimeInterval = 300,
        enableLocalStorage: Bool = true,
        enableBackgroundRefresh: Bool = true
    ) -> FeatureFlagConfiguration {
        return FeatureFlagConfiguration(
            remoteURL: remoteURL,
            fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
            refreshInterval: refreshInterval,
            enableLocalStorage: enableLocalStorage,
            enableBackgroundRefresh: enableBackgroundRefresh
        )
    }
}

// MARK: - DependencyInjector Extension
extension DependencyInjector {
    
    /// Get Feature Flag Manager
    func getFeatureFlagManager() -> FeatureFlagManager {
        return resolve(FeatureFlagManager.self)
    }
    
    /// Get Feature Flag Service
    func getFeatureFlagService() -> FeatureFlagServiceProtocol {
        return resolve(FeatureFlagServiceProtocol.self)
    }
}

// MARK: - Feature Flag Testing Support
#if DEBUG
extension FeatureFlagManager {
    
    /// Test helper for feature flags
    struct FeatureFlagTestHelper {
        static let shared = FeatureFlagTestHelper()
        
        private init() {}
        
        /// Create test configuration
        func createTestConfiguration() -> FeatureFlagConfiguration {
            return FeatureFlagConfiguration(
                remoteURL: "https://github.com/EmerBV/figrclub-feature-flags/blob/main/test/flags.json",
                fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, 1) }),
                refreshInterval: 10,
                enableLocalStorage: false,
                enableBackgroundRefresh: false
            )
        }
        
        /// Create mock service
        func createMockService() -> MockFeatureFlagService {
            return MockFeatureFlagService()
        }
    }
}

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
