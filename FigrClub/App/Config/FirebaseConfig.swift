//
//  FirebaseConfig.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseMessaging
import FirebaseRemoteConfig
import UserNotifications

// MARK: - Firebase Configuration
final class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    func configure() {
        // Configure Firebase
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            Logger.shared.fatal("Failed to load GoogleService-Info.plist", category: "firebase")
            return
        }
        
        FirebaseApp.configure(options: options)
        
        // Configure individual services
        configureAnalytics()
        configureCrashlytics()
        configureMessaging()
        configureRemoteConfig()
        
        Logger.shared.info("Firebase configured successfully", category: "firebase")
    }
    
    // MARK: - Analytics Configuration
    private func configureAnalytics() {
        guard AppConfig.FeatureFlags.enableAnalytics else {
            Analytics.setAnalyticsCollectionEnabled(false)
            Logger.shared.info("Analytics disabled via feature flag", category: "firebase")
            return
        }
        
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Set default parameters
        Analytics.setDefaultEventParameters([
            "app_version": AppConfig.AppInfo.version,
            "build_number": AppConfig.AppInfo.buildNumber,
            "environment": AppConfig.Environment.current.rawValue
        ])
        
        Logger.shared.info("Analytics configured successfully", category: "firebase")
    }
    
    // MARK: - Crashlytics Configuration
    private func configureCrashlytics() {
        guard AppConfig.FeatureFlags.enableCrashReporting else {
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            Logger.shared.info("Crashlytics disabled via feature flag", category: "firebase")
            return
        }
        
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Set custom keys
        Crashlytics.crashlytics().setCustomValue(AppConfig.AppInfo.version, forKey: "app_version")
        Crashlytics.crashlytics().setCustomValue(AppConfig.AppInfo.buildNumber, forKey: "build_number")
        Crashlytics.crashlytics().setCustomValue(AppConfig.Environment.current.rawValue, forKey: "environment")
        
        Logger.shared.info("Crashlytics configured successfully", category: "firebase")
    }
    
    // MARK: - Messaging Configuration
    private func configureMessaging() {
        guard AppConfig.FeatureFlags.enablePushNotifications else {
            Logger.shared.info("Push notifications disabled via feature flag", category: "firebase")
            return
        }
        
        Messaging.messaging().delegate = self
        
        // Request notification permissions
        requestNotificationPermissions()
        
        Logger.shared.info("Messaging configured successfully", category: "firebase")
    }
    
    // MARK: - Remote Config Configuration
    private func configureRemoteConfig() {
        let remoteConfig = RemoteConfig.remoteConfig()
        
        // Set default values
        let defaults: [String: NSObject] = [
            "feature_chat_enabled": true as NSObject,
            "feature_stories_enabled": true as NSObject,
            "feature_live_streaming_enabled": false as NSObject,
            "marketplace_commission_rate": 5.0 as NSObject,
            "max_image_upload_size_mb": 10.0 as NSObject,
            "api_timeout_seconds": 30.0 as NSObject
        ]
        
        remoteConfig.setDefaults(defaults)
        
        // Set fetch interval based on environment
        let settings = RemoteConfigSettings()
        switch AppConfig.Environment.current {
        case .development:
            settings.minimumFetchInterval = 0 // No throttling in development
        case .staging:
            settings.minimumFetchInterval = 300 // 5 minutes
        case .production:
            settings.minimumFetchInterval = 3600 // 1 hour
        }
        
        remoteConfig.configSettings = settings
        
        // Fetch and activate
        remoteConfig.fetchAndActivate { [weak self] status, error in
            if let error = error {
                Logger.shared.error("Remote Config fetch failed", error: error, category: "firebase")
            } else {
                Logger.shared.info("Remote Config fetched successfully", category: "firebase")
                self?.processRemoteConfigValues(remoteConfig)
            }
        }
    }
    
    // MARK: - Notification Permissions
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                Logger.shared.error("Notification permission request failed", error: error, category: "firebase")
            } else {
                Logger.shared.info("Notification permission granted: \(granted)", category: "firebase")
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: - Remote Config Processing
    private func processRemoteConfigValues(_ remoteConfig: RemoteConfig) {
        // Update app configuration based on remote config
        
        let chatEnabled = remoteConfig["feature_chat_enabled"].boolValue
        let storiesEnabled = remoteConfig["feature_stories_enabled"].boolValue
        let liveStreamingEnabled = remoteConfig["feature_live_streaming_enabled"].boolValue
        
        // Update feature flags
        RemoteFeatureFlags.shared.updateFlags(
            chatEnabled: chatEnabled,
            storiesEnabled: storiesEnabled,
            liveStreamingEnabled: liveStreamingEnabled
        )
        
        // Log changes
        Logger.shared.info("Remote Config values updated - Chat: \(chatEnabled), Stories: \(storiesEnabled), Live: \(liveStreamingEnabled)", category: "firebase")
    }
}

// MARK: - Messaging Delegate
extension FirebaseConfig: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Logger.shared.info("FCM registration token received", category: "firebase")
        
        // Send token to server
        if let token = fcmToken {
            Task {
                await NotificationService.shared.registerDeviceToken(token)
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        Logger.shared.info("Received remote message: \(remoteMessage.appData)", category: "firebase")
    }
}

// MARK: - Notification Center Delegate
extension FirebaseConfig: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle foreground notifications
        Logger.shared.info("Received foreground notification", category: "firebase")
        
        // Show notification in foreground
        completionHandler([[.banner, .sound, .badge]])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification taps
        let userInfo = response.notification.request.content.userInfo
        Logger.shared.info("User tapped notification: \(userInfo)", category: "firebase")
        
        // Process notification action
        NotificationService.shared.handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
}

// MARK: - Remote Feature Flags
final class RemoteFeatureFlags: ObservableObject {
    static let shared = RemoteFeatureFlags()
    
    @Published var chatEnabled = true
    @Published var storiesEnabled = true
    @Published var liveStreamingEnabled = false
    @Published var commissionRate: Double = 5.0
    @Published var maxImageUploadSizeMB: Double = 10.0
    @Published var apiTimeoutSeconds: Double = 30.0
    
    private init() {}
    
    func updateFlags(
        chatEnabled: Bool,
        storiesEnabled: Bool,
        liveStreamingEnabled: Bool
    ) {
        DispatchQueue.main.async {
            self.chatEnabled = chatEnabled
            self.storiesEnabled = storiesEnabled
            self.liveStreamingEnabled = liveStreamingEnabled
        }
    }
    
    func updateCommissionRate(_ rate: Double) {
        DispatchQueue.main.async {
            self.commissionRate = rate
        }
    }
}
