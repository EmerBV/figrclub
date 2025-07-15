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
    func setupPeriodicRefresh()
    func stopPeriodicRefresh()
    
    // Sync methods for SwiftUI views
    func isFeatureEnabledSync(_ key: FeatureFlagKey) -> Bool
    func getFeatureValueSync(_ key: FeatureFlagKey) -> Int
}

// MARK: - Feature Flag Manager Implementation
@MainActor
final class FeatureFlagManager: FeatureFlagManagerProtocol {
    
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
        await MainActor.run {
            flags[key.rawValue] = FeatureFlag(id: key.rawValue, value: value)
        }
        
        return value
    }
    
    func refreshFlags() async throws {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            let fetchedFlags = try await service.fetchRemoteFlags()
            
            await MainActor.run {
                updateFlags(with: fetchedFlags)
                isLoading = false
                lastRefreshTime = Date()
            }
            
            Logger.info("✅ FeatureFlagManager: Successfully refreshed \(fetchedFlags.count) flags")
            
        } catch let error as FeatureFlagError {
            await MainActor.run {
                lastError = error
                isLoading = false
            }
            
            Logger.error("❌ FeatureFlagManager: Failed to refresh flags: \(error)")
            throw error
        }
    }
    
    func getAllFlags() async -> [FeatureFlag] {
        if flags.isEmpty {
            let serviceFlags = await service.getAllFlags()
            await MainActor.run {
                updateFlags(with: serviceFlags)
            }
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
        await MainActor.run {
            updateFlags(with: serviceFlags)
        }
        
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
                content
                    .opacity(0.5)
            }
        }
        .disabled(!featureFlagManager.isFeatureEnabledSync(key))
    }
}

// MARK: - Feature Flag Hook for SwiftUI
@propertyWrapper
struct FeatureFlagEnabled: DynamicProperty {
    private let key: FeatureFlagKey
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    var wrappedValue: Bool {
        featureFlagManager.isFeatureEnabledSync(key)
    }
    
    init(_ key: FeatureFlagKey) {
        self.key = key
    }
}

// MARK: - Feature Flag Value Hook
@propertyWrapper
struct FeatureFlagValue: DynamicProperty {
    private let key: FeatureFlagKey
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    var wrappedValue: Int {
        featureFlagManager.getFeatureValueSync(key)
    }
    
    init(_ key: FeatureFlagKey) {
        self.key = key
    }
}

// MARK: - Conditional View Based on Feature Flag
struct ConditionalFeatureView<EnabledContent: View, DisabledContent: View>: View {
    let key: FeatureFlagKey
    let enabledContent: EnabledContent
    let disabledContent: DisabledContent
    
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    init(
        key: FeatureFlagKey,
        @ViewBuilder enabled: () -> EnabledContent,
        @ViewBuilder disabled: () -> DisabledContent
    ) {
        self.key = key
        self.enabledContent = enabled()
        self.disabledContent = disabled()
    }
    
    var body: some View {
        Group {
            if featureFlagManager.isFeatureEnabledSync(key) {
                enabledContent
            } else {
                disabledContent
            }
        }
    }
}

// MARK: - Feature Flag Debug View
#if DEBUG
struct FeatureFlagDebugView: View {
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    @State private var flags: [FeatureFlag] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar feature flags...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Refresh button
                Button(action: refreshFlags) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Actualizar Flags")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                // Flags list
                List(filteredFlags, id: \.id) { flag in
                    FeatureFlagRow(flag: flag)
                }
                .refreshable {
                    await refreshFlags()
                }
            }
            .navigationTitle("Feature Flags")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadFlags()
            }
        }
    }
    
    private var filteredFlags: [FeatureFlag] {
        if searchText.isEmpty {
            return flags
        } else {
            return flags.filter { flag in
                flag.id.localizedCaseInsensitiveContains(searchText) ||
                FeatureFlagKey(rawValue: flag.id)?.description.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func loadFlags() {
        Task {
            let allFlags = await featureFlagManager.getAllFlags()
            await MainActor.run {
                flags = allFlags.sorted { $0.id < $1.id }
            }
        }
    }
    
    private func refreshFlags() {
        isLoading = true
        Task {
            do {
                try await featureFlagManager.refreshFlags()
                await loadFlags()
            } catch {
                Logger.error("Failed to refresh flags: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct FeatureFlagRow: View {
    let flag: FeatureFlag
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(flag.id)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let key = FeatureFlagKey(rawValue: flag.id) {
                    Text(key.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let lastUpdated = flag.lastUpdated {
                    Text("Updated: \(lastUpdated.formatted(.relative(presentation: .numeric)))")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text(flag.isEnabled ? "ON" : "OFF")
                        .font(.caption.weight(.bold))
                        .foregroundColor(flag.isEnabled ? .green : .red)
                    
                    Circle()
                        .fill(flag.isEnabled ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                }
                
                Text("Value: \(flag.value)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
#endif
