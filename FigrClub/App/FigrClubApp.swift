//
//  FigrClubApp.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct FigrClubApp: App {
    
    // MARK: - Properties
    @StateObject private var authStateManager: AuthStateManager
    @StateObject private var featureFlagManager: FeatureFlagManager
    
    // MARK: - Initialization
    init() {
        // Initialize dependency injection (auto-configures in init)
        _ = DependencyInjector.shared
        
        // Initialize managers on main actor to avoid actor isolation issues
        let authManager = MainActor.assumeIsolated {
            DependencyInjector.shared.resolve(AuthStateManager.self)
        }
        let flagManager = MainActor.assumeIsolated {
            DependencyInjector.shared.resolve(FeatureFlagManager.self)
        }
        
        self._authStateManager = StateObject(wrappedValue: authManager)
        self._featureFlagManager = StateObject(wrappedValue: flagManager)
        
        // Setup logging after all stored properties are initialized
        setupLogging()
        
#if DEBUG
        // Perform architecture health check in debug mode
        performArchitectureHealthCheck()
#endif
    }
    
    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStateManager)
                .environmentObject(featureFlagManager)
                .onAppear {
                    Task {
                        await setupFeatureFlags()
                    }
                    Logger.info("🚀 FigrClub app launched successfully")
                }
        }
    }
}

// MARK: - Feature Flags Setup
extension FigrClubApp {
    
    /// Setup Feature Flags in App initialization
    @MainActor
    private func setupFeatureFlags() async {
        Logger.info("🚩 FigrClubApp: Setting up feature flags...")
        
        do {
            try await featureFlagManager.refreshFlags()
            Logger.info("✅ FigrClubApp: Feature flags initialized successfully")
        } catch {
            Logger.warning("⚠️ FigrClubApp: Failed to initialize feature flags: \(error)")
            // Continue with fallback flags - don't crash the app
        }
    }
}

// MARK: - Private Setup Methods
private extension FigrClubApp {
    
    func setupLogging() {
        Logger.info("🔧 FigrClub: Initializing logging system...")
        
#if DEBUG
        Logger.info("📱 Environment: Development")
        Logger.info("🌍 Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        Logger.info("📦 App Version: \(AppConfig.AppInfo.version)")
        Logger.info("🔢 Build Number: \(AppConfig.AppInfo.buildNumber)")
#else
        Logger.info("📱 Environment: Production")
#endif
        // Configure Firebase
        FirebaseApp.configure()
        Logger.info("🔥 Firebase configured successfully")
        Logger.info("✅ Logging system initialized")
    }
    
#if DEBUG
    func performArchitectureHealthCheck() {
        Logger.info("🏥 FigrClub: Starting architecture health check...")
        
        let criticalServices: [(String, Bool)] = [
            ("NetworkDispatcher", DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self) != nil),
            ("AuthStateManager", DependencyInjector.shared.resolveOptional(AuthStateManager.self) != nil),
            ("TokenManager", DependencyInjector.shared.resolveOptional(TokenManager.self) != nil),
            ("AuthService", DependencyInjector.shared.resolveOptional(AuthServiceProtocol.self) != nil),
            ("ValidationService", DependencyInjector.shared.resolveOptional(ValidationServiceProtocol.self) != nil),
            ("SecureStorage", DependencyInjector.shared.resolveOptional(SecureStorageProtocol.self) != nil),
            ("NetworkLogger", DependencyInjector.shared.resolveOptional(NetworkLoggerProtocol.self) != nil),
            ("APIConfiguration", DependencyInjector.shared.resolveOptional(APIConfigurationProtocol.self) != nil)
        ]
        
        let healthScore = criticalServices.filter { $0.1 }.count
        let totalServices = criticalServices.count
        
        Logger.info("🏥 Architecture Health: \(healthScore)/\(totalServices) services online")
        
        for (service, isHealthy) in criticalServices {
            Logger.info("  \(isHealthy ? "✅" : "❌") \(service)")
        }
        
        if healthScore == totalServices {
            Logger.info("🎉 Architecture is fully operational!")
            logArchitectureDetails()
        } else {
            Logger.warning("⚠️ Some services are unavailable - check dependency configuration")
            logMissingServices(criticalServices.filter { !$0.1 }.map { $0.0 })
        }
    }
    
    func logArchitectureDetails() {
        Logger.info("📋 Architecture Details:")
        Logger.info("  🌐 Network Layer: NetworkDispatcher + URLSessionProvider")
        Logger.info("  🔐 Auth Layer: AuthService + TokenManager + SecureStorage")
        Logger.info("  📝 Validation Layer: ValidationService")
        Logger.info("  🏗️ DI Container: Swinject")
        Logger.info("  📊 Logging: Unified Logger with os.Logger")
    }
    
    func logMissingServices(_ missingServices: [String]) {
        Logger.error("❌ Missing Services:")
        for service in missingServices {
            Logger.error("  - \(service)")
        }
        Logger.error("🔧 Check assembly configurations in DI container")
    }
#endif
}

// MARK: - Feature Flag App Extensions
extension FigrClubApp {
    
    /// Check if a feature is enabled at app level
    @MainActor
    func isFeatureEnabled(_ key: FeatureFlagKey) -> Bool {
        return featureFlagManager.isFeatureEnabledSync(key)
    }
    
    /// Get feature flag value at app level
    @MainActor
    func getFeatureValue(_ key: FeatureFlagKey) -> Int {
        return featureFlagManager.getFeatureValueSync(key)
    }
}
