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
        Logger.shared.info("FigrClub app starting - Version: \(AppConfig.AppInfo.version)", category: "app")
        
        // Configure Analytics
        configureAnalytics()
        
        // Setup global configurations
        setupGlobalConfigurations()
    }
    
    private func configureAnalytics() {
        Analytics.shared.configure()
        Analytics.shared.logEvent("app_launch", parameters: [
            "app_version": AppConfig.AppInfo.version,
            "build_number": AppConfig.AppInfo.buildNumber,
            "platform": "iOS"
        ])
    }
    
    private func setupGlobalConfigurations() {
        // Setup networking
        configureNetworking()
        
        // Setup accessibility
        configureAccessibility()
        
        // Setup appearance
        configureAppearance()
    }
    
    private func configureNetworking() {
        // Configure URLSession global settings
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConfig.API.timeout
        configuration.timeoutIntervalForResource = AppConfig.API.timeout * 2
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        
        // Set user agent
        configuration.httpAdditionalHeaders = [
            "User-Agent": "FigrClub-iOS/\(AppConfig.AppInfo.version)"
        ]
    }
    
    private func configureAccessibility() {
        // Setup VoiceOver settings
        if UIAccessibility.isVoiceOverRunning {
            Logger.shared.info("VoiceOver is running", category: "accessibility")
        }
    }
    
    private func configureAppearance() {
        // Configure global tint color
        UIView.appearance().tintColor = UIColor(.figrPrimary)
        
        // Configure scroll indicators
        UIScrollView.appearance().showsVerticalScrollIndicator = true
        UIScrollView.appearance().showsHorizontalScrollIndicator = false
    }
    
    private func setupAppAppearance() {
        // Additional appearance setup that requires the view hierarchy
        Analytics.shared.logScreenView(screenName: "App Launch")
    }
    
    // MARK: - Scene Phase Handling
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            handleAppBecameActive()
        case .inactive:
            handleAppBecameInactive()
        case .background:
            handleAppEnteredBackground()
        @unknown default:
            break
        }
    }
    
    private func handleAppBecameActive() {
        Logger.shared.info("App became active", category: "app")
        
        Analytics.shared.resume()
        
        // Check for app updates
        Task {
            await checkForAppUpdates()
        }
        
        // Refresh authentication if needed
        Task { @MainActor in
            if let authManager = try? DependencyContainer.shared.resolve(AuthManager.self) {
                _ = await authManager.refreshTokenIfNeeded()
            }
        }
    }
    
    private func handleAppBecameInactive() {
        Logger.shared.info("App became inactive", category: "app")
        Analytics.shared.pause()
    }
    
    private func handleAppEnteredBackground() {
        Logger.shared.info("App entered background", category: "app")
        
        
        
        // Save user data and app state
        saveAppState()
        
        // Clear sensitive data if needed
        clearSensitiveDataIfNeeded()
    }
    
    private func checkForAppUpdates() async {
        // Check for app updates logic
        Logger.shared.info("Checking for app updates", category: "app")
    }
    
    private func saveAppState() {
        // Save current app state
        Logger.shared.info("Saving app state", category: "app")
    }
    
    private func clearSensitiveDataIfNeeded() {
        // Clear sensitive data if app security policy requires it
        Logger.shared.info("Clearing sensitive data", category: "app")
    }
}

// MARK: - Remote Config Manager
final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()
    
    @Published var isMaintenanceMode = false
    @Published var maintenanceMessage = "Estamos realizando mejoras en FigrClub. Volveremos pronto."
    @Published var estimatedMaintenanceEnd: Date?
    @Published var minAppVersion = "1.0.0"
    @Published var forceUpdateEnabled = false
    @Published var features: [String: Bool] = [:]
    
    private init() {
        loadRemoteConfig()
    }
    
    func loadRemoteConfig() {
        // En producción, esto cargaría desde Firebase Remote Config
#if DEBUG
        // Valores por defecto para desarrollo
        isMaintenanceMode = false
        forceUpdateEnabled = false
        features = [
            "marketplace": true,
            "stories": false,
            "live": false,
            "darkMode": true
        ]
#else
        fetchRemoteConfig()
#endif
    }
    
    private func fetchRemoteConfig() {
        // Implementar fetch desde Firebase Remote Config
        Logger.shared.info("Fetching remote config", category: "config")
    }
    
    func isFeatureEnabled(_ feature: String) -> Bool {
        return features[feature] ?? false
    }
}

// MARK: - Accessibility Announcement Manager
final class AccessibilityAnnouncementManager: ObservableObject {
    static let shared = AccessibilityAnnouncementManager()
    
    private init() {}
    
    func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: priority, argument: message)
        }
        
        Logger.shared.info("Accessibility announcement: \(message)", category: "accessibility")
    }
    
    func announcePageChange(_ pageName: String) {
        announce("Navegando a \(pageName)", priority: .screenChanged)
    }
    
    func announceStatusChange(_ status: String) {
        announce(status, priority: .announcement)
    }
}

// MARK: - App Delegate Implementation (Additional Methods)
extension AppDelegate {
    
    // MARK: - URL Handling
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Logger.shared.info("App opened with URL: \(url)", category: "app")
        
        // Handle deep links
        return handleDeepLink(url)
    }
    
    private func handleDeepLink(_ url: URL) -> Bool {
        // Parse and handle deep link
        // This would route to appropriate screens
        return true
    }
    
    // MARK: - Background Processing
    func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.shared.info("App entered background", category: "app")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.shared.info("App will enter foreground", category: "app")
    }
}
