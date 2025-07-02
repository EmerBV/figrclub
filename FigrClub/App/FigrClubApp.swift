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
    // MARK: - State Objects
    @StateObject private var authManager = DependencyContainer.shared.resolve(AuthManager.self)
    @StateObject private var remoteConfigManager = RemoteConfigManager.shared
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var announcementManager = AccessibilityAnnouncementManager.shared
    
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - Scene Phase
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(remoteConfigManager)
                .environmentObject(announcementManager)
                .onAppear {
                    setupAppAppearance()
                }
                .onChange(of: scenePhase) { phase in
                    handleScenePhaseChange(phase)
                }
                .overlay(
                    Group {
                        if remoteConfigManager.isMaintenanceMode {
                            MaintenanceView()
                        }
                    }
                )
#if DEBUG
                .overlay(
                    Group {
                        if DebugConfig.showPerformanceOverlay {
                            PerformanceOverlayView()
                        }
                    },
                    alignment: .topTrailing
                )
#endif
        }
    }
    
    // MARK: - App Setup
    private func setupApp() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Setup logging
        Logger.shared.info("FigrClub app starting - Version: \(BuildConfig.fullVersion)", category: "app")
        
        // Log build configuration
        logBuildConfiguration()
        
        // Setup analytics
        if AppConfig.Features.analyticsEnabled {
            Analytics.shared.configure()
        }
        
        // Setup crash reporting
        if AppConfig.Features.crashReportingEnabled {
            setupCrashReporting()
        }
    }
    
    private func setupAppAppearance() {
        // Configure global appearance
        setupNavigationAppearance()
        setupTabBarAppearance()
        
        Logger.shared.info("App appearance configured", category: "app")
    }
    
    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func logBuildConfiguration() {
        Logger.shared.info("Build Configuration:", category: "app")
        Logger.shared.info("- Environment: \(AppConfig.Environment.current)", category: "app")
        Logger.shared.info("- Version: \(BuildConfig.fullVersion)", category: "app")
        Logger.shared.info("- Bundle ID: \(BuildConfig.bundleId)", category: "app")
        Logger.shared.info("- Debug: \(BuildConfig.isDebugBuild)", category: "app")
        Logger.shared.info("- TestFlight: \(BuildConfig.isTestFlightBuild)", category: "app")
    }
    
    private func setupCrashReporting() {
        // Setup Firebase Crashlytics or other crash reporting
        Logger.shared.info("Crash reporting configured", category: "app")
    }
    
    // MARK: - Scene Phase Handling
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Logger.shared.info("App became active", category: "app")
            handleAppBecameActive()
            
        case .inactive:
            Logger.shared.info("App became inactive", category: "app")
            handleAppBecameInactive()
            
        case .background:
            Logger.shared.info("App entered background", category: "app")
            handleAppEnteredBackground()
            
        @unknown default:
            break
        }
    }
    
    private func handleAppBecameActive() {
        // Refresh remote config
        remoteConfigManager.loadRemoteConfig()
        
        // Check app version
        checkAppVersion()
        
        // Resume analytics
        Analytics.shared.resume()
    }
    
    private func handleAppBecameInactive() {
        // Pause analytics
        Analytics.shared.pause()
    }
    
    private func handleAppEnteredBackground() {
        // Clear sensitive data if needed
        // Save app state
        // Cancel non-essential network requests
    }
    
    private func checkAppVersion() {
        let currentVersion = BuildConfig.version
        if !remoteConfigManager.isAppVersionSupported(currentVersion) {
            // Show update required alert
            Logger.shared.warning("App version \(currentVersion) is not supported", category: "app")
        }
    }
}
