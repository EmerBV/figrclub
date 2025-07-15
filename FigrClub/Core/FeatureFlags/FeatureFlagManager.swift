//
//  FeatureFlagManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Feature Flag Manager Protocol
protocol FeatureFlagManagerProtocol: ObservableObject {
    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool
    func getFeatureValue(_ key: FeatureFlagKey) async -> Int
    func refreshFlags() async throws
    func getAllFlags() async -> [FeatureFlag]
    func setupPeriodicRefresh() async
    func stopPeriodicRefresh() async
    
    // Sync methods for SwiftUI views
    func isFeatureEnabledSync(_ key: FeatureFlagKey) -> Bool
    func getFeatureValueSync(_ key: FeatureFlagKey) -> Int
}

// MARK: - Feature Flag Manager Implementation
@MainActor
final class FeatureFlagManager: ObservableObject, FeatureFlagManagerProtocol {
    
    // MARK: - Published Properties
    @Published public var flags: [String: FeatureFlag] = [:]
    @Published private var isLoading = false
    @Published private var lastError: FeatureFlagError?
    @Published private var lastRefreshTime: Date?
    
    // MARK: - Properties
    private let service: FeatureFlagServiceProtocol
    private let configuration: FeatureFlagConfiguration
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(service: FeatureFlagServiceProtocol, configuration: FeatureFlagConfiguration) {
        self.service = service
        self.configuration = configuration
        
        Task {
            await loadInitialFlags()
            await setupPeriodicRefresh()
        }
        
        Logger.info("🚩 FeatureFlagManager: Initialized")
    }
    
    // MARK: - Public Methods
    
    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool {
        let value = await getFeatureValue(key)
        return value == 1
    }
    
    func getFeatureValue(_ key: FeatureFlagKey) async -> Int {
        // Check in-memory cache first
        if let cachedFlag = flags[key.rawValue] {
            return cachedFlag.value
        }
        
        // Fetch from service
        let value = await service.getFeatureValue(key)
        
        // Update cache
        let newFlag = FeatureFlag(id: key.rawValue, value: value)
        flags[key.rawValue] = newFlag
        
        return value
    }
    
    func refreshFlags() async throws {
        isLoading = true
        lastError = nil
        
        do {
            let fetchedFlags = try await service.fetchRemoteFlags()
            
            updateFlags(with: fetchedFlags)
            isLoading = false
            lastRefreshTime = Date()
            
            Logger.info("✅ FeatureFlagManager: Successfully refreshed \(fetchedFlags.count) flags")
            
        } catch let error as FeatureFlagError {
            lastError = error
            isLoading = false
            
            Logger.error("❌ FeatureFlagManager: Failed to refresh flags: \(error)")
            throw error
        }
    }
    
    func getAllFlags() async -> [FeatureFlag] {
        if flags.isEmpty {
            let serviceFlags = await service.getAllFlags()
            updateFlags(with: serviceFlags)
        }
        
        return Array(flags.values)
    }
    
    func setupPeriodicRefresh() async {
        await service.setupPeriodicRefresh()
    }
    
    func stopPeriodicRefresh() async {
        await service.stopPeriodicRefresh()
    }
    
    // MARK: - Sync Methods for SwiftUI
    
    func isFeatureEnabledSync(_ key: FeatureFlagKey) -> Bool {
        return flags[key.rawValue]?.isEnabled ?? (configuration.fallbackFlags[key] == 1)
    }
    
    func getFeatureValueSync(_ key: FeatureFlagKey) -> Int {
        return flags[key.rawValue]?.value ?? configuration.fallbackFlags[key] ?? key.defaultValue
    }
    
    // MARK: - Private Methods
    
    private func loadInitialFlags() async {
        let serviceFlags = await service.getAllFlags()
        updateFlags(with: serviceFlags)
        
        // Try to fetch fresh flags in background
        Task {
            do {
                try await refreshFlags()
            } catch {
                Logger.warning("⚠️ FeatureFlagManager: Initial remote fetch failed, using cached/fallback flags")
            }
        }
    }
    
    private func updateFlags(with newFlags: [FeatureFlag]) {
        for flag in newFlags {
            flags[flag.id] = flag
        }
    }
}

// MARK: - Feature Flag Extensions for SwiftUI
extension FeatureFlagManager {
    
    /// Subscribe to specific feature flag changes
    func publisher(for key: FeatureFlagKey) -> AnyPublisher<Bool, Never> {
        $flags
            .map { flags in
                flags[key.rawValue]?.isEnabled ?? (self.configuration.fallbackFlags[key] == 1)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    /// Get all enabled features
    var enabledFeatures: [FeatureFlagKey] {
        return FeatureFlagKey.allCases.filter { key in
            isFeatureEnabledSync(key)
        }
    }
    
    /// Get feature flag status summary
    var statusSummary: String {
        let enabled = enabledFeatures.count
        let total = FeatureFlagKey.allCases.count
        return "\(enabled)/\(total) features enabled"
    }
}

// MARK: - View Modifier for Feature Flags
struct FeatureFlagModifier: ViewModifier {
    let key: FeatureFlagKey
    let fallback: Bool
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    func body(content: Content) -> some View {
        Group {
            if featureFlagManager.isFeatureEnabledSync(key) {
                content
            } else if fallback {
                content
            } else {
                EmptyView()
            }
        }
    }
}

extension View {
    /// Show view only if feature flag is enabled
    func featureFlag(_ key: FeatureFlagKey, fallback: Bool = false) -> some View {
        modifier(FeatureFlagModifier(key: key, fallback: fallback))
    }
}

// MARK: - Feature Flag Button
struct FeatureFlagButton<Content: View>: View {
    let key: FeatureFlagKey
    let action: () -> Void
    let content: Content
    let disabledContent: Content?
    
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    init(
        key: FeatureFlagKey,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder disabledContent: () -> Content? = { nil }
    ) {
        self.key = key
        self.action = action
        self.content = content()
        self.disabledContent = disabledContent()
    }
    
    var body: some View {
        Button(action: action) {
            if featureFlagManager.isFeatureEnabledSync(key) {
                content
            } else if let disabledContent = disabledContent {
                disabledContent
            } else {
                EmptyView()
            }
        }
        .disabled(!featureFlagManager.isFeatureEnabledSync(key))
    }
}

// MARK: - Feature Flag Testing Support
#if DEBUG
extension FeatureFlagManager {
    
    /// Override feature flag for testing
    func overrideFeature(_ key: FeatureFlagKey, value: Int) {
        let testFlag = FeatureFlag(id: key.rawValue, value: value)
        flags[key.rawValue] = testFlag
        Logger.debug("🧪 FeatureFlagManager: Override \(key.rawValue) = \(value)")
    }
    
    /// Reset all overrides
    func resetOverrides() {
        flags.removeAll()
        Logger.debug("🧪 FeatureFlagManager: All overrides reset")
    }
    
    /// Enable all features for testing
    func enableAllFeatures() {
        for key in FeatureFlagKey.allCases {
            overrideFeature(key, value: 1)
        }
        Logger.debug("🧪 FeatureFlagManager: All features enabled for testing")
    }
    
    /// Disable all features for testing
    func disableAllFeatures() {
        for key in FeatureFlagKey.allCases {
            overrideFeature(key, value: 0)
        }
        Logger.debug("🧪 FeatureFlagManager: All features disabled for testing")
    }
}
#endif
