//
//  NotificationService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import UserNotifications
import FirebaseMessaging
import Combine

// MARK: - Notification Service
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    // MARK: - App State Observers
    
    @objc private func applicationDidBecomeActive() {
        getNotificationSettings()
        clearBadge()
    }
    
    @objc private func applicationDidEnterBackground() {
        // Save any pending notification state
    }
    
    // MARK: - Testing
    
    func sendTestNotification() async {
        guard isAuthorized else {
            Logger.shared.warning("Cannot send test notification - not authorized", category: "notifications")
            return
        }
        
        do {
            try await apiService
                .request(endpoint: .testNotification, body: nil)
                .async()
            
            Logger.shared.info("Test notification sent", category: "notifications")
            
        } catch {
            Logger.shared.error("Failed to send test notification", error: error, category: "notifications")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Logger.shared.info("Will present notification: \(notification.request.identifier)", category: "notifications")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        
        Analytics.shared.logEvent("notification_received_foreground", parameters: [
            "notification_id": notification.request.identifier
        ])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Logger.shared.info("Did receive notification response: \(response.notification.request.identifier)", category: "notifications")
        
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        Logger.shared.info("User opened notification settings", category: "notifications")
        
        Analytics.shared.logEvent("notification_settings_opened", parameters: [:])
    }
}

// MARK: - MessagingDelegate
extension NotificationService: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Logger.shared.info("FCM registration token received", category: "notifications")
        
        guard let fcmToken = fcmToken else {
            Logger.shared.warning("FCM token is nil", category: "notifications")
            return
        }
        
        // Register token with backend
        Task {
            await registerDeviceToken(fcmToken)
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        Logger.shared.info("Received remote message: \(remoteMessage.appData)", category: "notifications")
        
        Analytics.shared.logEvent("fcm_message_received", parameters: [
            "message_id": remoteMessage.messageID ?? "unknown"
        ])
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToPost = Notification.Name("navigateToPost")
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToMarketplaceItem = Notification.Name("navigateToMarketplaceItem")
    static let navigateToConversation = Notification.Name("navigateToConversation")
    static let refreshNotifications = Notification.Name("refreshNotifications")
}

// MARK: - Notification Preferences
struct NotificationPreferences: Codable {
    var likesEnabled: Bool = true
    var commentsEnabled: Bool = true
    var followsEnabled: Bool = true
    var newPostsEnabled: Bool = true
    var marketplaceEnabled: Bool = true
    var systemEnabled: Bool = true
    var marketingEnabled: Bool = false
    
    static let `default` = NotificationPreferences()
    
    private static let userDefaultsKey = "notification_preferences"
    
    static func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}
