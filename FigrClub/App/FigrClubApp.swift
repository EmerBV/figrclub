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
        // Enable accessibility features
        UIAccessibility.buttonShapesEnabled = true
        UIAccessibility.isGuidedAccessEnabled = false
        
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
        
        // Refresh remote config
        remoteConfigManager.loadRemoteConfig()
        
        // Clear notification badge
        NotificationService.shared.clearBadge()
        
        // Check authentication status
        Task {
            await authManager.checkAuthenticationStatus()
        }
    }
    
    private func handleAppBecameInactive() {
        Logger.shared.info("App became inactive", category: "app")
    }
    
    private func handleAppEnteredBackground() {
        Logger.shared.info("App entered background", category: "app")
        
        Analytics.shared.pause()
        
        // Save any pending data
        savePendingData()
        
        // Schedule background tasks
        scheduleBackgroundTasks()
    }
    
    // MARK: - Background Tasks
    private func scheduleBackgroundTasks() {
        // Schedule background app refresh
        // This would be implemented based on specific needs
    }
    
    private func savePendingData() {
        // Save any unsaved user data
        // This would be implemented based on specific needs
    }
    
    // MARK: - App Updates
    private func checkForAppUpdates() async {
        // Check App Store for updates
        // This would be implemented with App Store Connect API
    }
}

// MARK: - Remote Config Manager
final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()
    
    @Published var isMaintenanceMode = false
    @Published var minimumAppVersion = "1.0.0"
    @Published var featuresEnabled: [String: Bool] = [:]
    
    private init() {
        loadRemoteConfig()
    }
    
    func loadRemoteConfig() {
        // Load configuration from Firebase Remote Config
        // For now, using default values
        isMaintenanceMode = false
        minimumAppVersion = "1.0.0"
        featuresEnabled = [
            "newPostCreation": true,
            "marketplaceEnabled": true,
            "pushNotifications": true,
            "analytics": true
        ]
        
        Logger.shared.info("Remote config loaded", category: "config")
    }
    
    func getSetting(_ key: String, defaultValue: String) -> String {
        // Get setting from remote config
        // For now, return default value
        return defaultValue
    }
    
    func getBoolSetting(_ key: String, defaultValue: Bool) -> Bool {
        return featuresEnabled[key] ?? defaultValue
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

// MARK: - Logger Implementation
final class Logger {
    static let shared = Logger()
    
    private init() {}
    
    func info(_ message: String, category: String = "general") {
        log(level: .info, message: message, category: category)
    }
    
    func warning(_ message: String, category: String = "general") {
        log(level: .warning, message: message, category: category)
    }
    
    func error(_ message: String, error: Error? = nil, category: String = "general") {
        var logMessage = message
        if let error = error {
            logMessage += " - Error: \(error.localizedDescription)"
        }
        log(level: .error, message: logMessage, category: category)
    }
    
    func fatal(_ message: String, category: String = "general") {
        log(level: .fatal, message: message, category: category)
    }
    
    private func log(level: LogLevel, message: String, category: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue.uppercased())] [\(category)] \(message)"
        
#if DEBUG
        print(logMessage)
#endif
        
        // Send to crash reporting service in production
#if !DEBUG
        if level == .error || level == .fatal {
            // Send to Crashlytics or similar service
        }
#endif
    }
}

enum LogLevel: String {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case fatal = "fatal"
}

// MARK: - Analytics Implementation
final class Analytics {
    static let shared = Analytics()
    
    private var isConfigured = false
    
    private init() {}
    
    func configure() {
        isConfigured = true
        Logger.shared.info("Analytics configured", category: "analytics")
    }
    
    func logEvent(_ name: String, parameters: [String: Any] = [:]) {
        guard isConfigured else { return }
        
        Logger.shared.info("Analytics event: \(name) with parameters: \(parameters)", category: "analytics")
        
        // Send to Firebase Analytics
#if !DEBUG
        // FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters)
#endif
    }
    
    func logScreenView(screenName: String) {
        logEvent("screen_view", parameters: ["screen_name": screenName])
    }
    
    func logLogin(method: String) {
        logEvent("login", parameters: ["method": method])
    }
    
    func logPostCreated(postType: String) {
        logEvent("post_created", parameters: ["post_type": postType])
    }
    
    func resume() {
        Logger.shared.info("Analytics resumed", category: "analytics")
    }
    
    func pause() {
        Logger.shared.info("Analytics paused", category: "analytics")
    }
}

// MARK: - Debug Configuration
#if DEBUG
struct DebugConfig {
    static let showPerformanceOverlay = false
    static let enableNetworkLogging = true
    static let useMockData = false
    static let bypassAuthentication = false
}

struct PerformanceOverlayView: View {
    @StateObject private var memoryManager = MemoryManager.shared
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("MEM: \(ByteCountFormatter.string(fromByteCount: Int64(memoryManager.memoryUsage), countStyle: .memory))")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            
            if memoryManager.isMemoryPressureHigh {
                Text("HIGH MEMORY")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
#endif

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
