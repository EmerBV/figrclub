//
//  NotificationService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import Combine

// MARK: - Notification Service
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let apiService: APIServiceProtocol = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        configure()
        setupObservers()
    }
    
    // MARK: - Configuration
    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        getNotificationSettings()
        
        Logger.shared.info("NotificationService configured", category: "notifications")
    }
    
    // MARK: - Authorization
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                isAuthorized = granted
            }
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            Logger.shared.info("Notification authorization: \(granted)", category: "notifications")
            return granted
            
        } catch {
            Logger.shared.error("Failed to request authorization", error: error, category: "notifications")
            return false
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
            
            Logger.shared.info("Notification status: \(settings.authorizationStatus.rawValue)", category: "notifications")
        }
    }
    
    // MARK: - Device Token Management
    func registerDeviceToken(_ token: String) async {
        let request = RegisterDeviceTokenRequest(
            token: token,
            deviceType: .ios,
            deviceName: UIDevice.current.name,
            appVersion: AppConfig.AppInfo.version,
            osVersion: UIDevice.current.systemVersion
        )
        
        do {
            let _: DeviceToken = try await apiService
                .request(endpoint: .registerDeviceToken, body: request)
                .async()
            
            Logger.shared.info("Device token registered successfully", category: "notifications")
            
        } catch {
            Logger.shared.error("Failed to register device token", error: error, category: "notifications")
        }
    }
    
    // MARK: - Notification Handling
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        Logger.shared.info("Handling notification tap: \(userInfo)", category: "notifications")
        
        // Extract notification data
        guard let entityType = userInfo["entityType"] as? String,
              let entityId = userInfo["entityId"] as? Int else {
            Logger.shared.warning("Invalid notification data", category: "notifications")
            return
        }
        
        // Navigate based on entity type
        switch entityType {
        case "POST":
            NotificationCenter.default.post(
                name: .navigateToPost,
                object: nil,
                userInfo: ["postId": entityId]
            )
        case "USER":
            NotificationCenter.default.post(
                name: .navigateToProfile,
                object: nil,
                userInfo: ["userId": entityId]
            )
        case "MARKETPLACE_ITEM":
            NotificationCenter.default.post(
                name: .navigateToMarketplaceItem,
                object: nil,
                userInfo: ["itemId": entityId]
            )
        case "CONVERSATION":
            NotificationCenter.default.post(
                name: .navigateToConversation,
                object: nil,
                userInfo: ["conversationId": entityId]
            )
        default:
            Logger.shared.info("Unknown entity type: \(entityType)", category: "notifications")
        }
        
        Analytics.shared.logEvent("notification_tapped", parameters: [
            "entity_type": entityType,
            "entity_id": entityId
        ])
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFCMTokenReceived(_:)),
            name: .fcmTokenReceived,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationTapFromFirebase(_:)),
            name: .handleNotificationTap,
            object: nil
        )
    }
    
    // MARK: - App State Observers
    
    @objc private func applicationDidBecomeActive() {
        getNotificationSettings()
        clearBadge()
    }
    
    @objc private func applicationDidEnterBackground() {
        // Save any pending notification state
    }
    
    @objc private func handleFCMTokenReceived(_ notification: Notification) {
        guard let token = notification.userInfo?["token"] as? String else { return }
        
        Task {
            await registerDeviceToken(token)
        }
    }
    
    @objc private func handleNotificationTapFromFirebase(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        handleNotificationTap(userInfo: userInfo)
    }
    
    // MARK: - Testing
    
    func sendTestNotification() async {
        guard isAuthorized else {
            Logger.shared.warning("Cannot send test notification - not authorized", category: "notifications")
            return
        }
        
        do {
            let _: EmptyResponse = try await apiService
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
        
        // Show notification in foreground
        completionHandler([.alert, .sound, .badge])
        
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
        
        if let fcmToken = fcmToken {
            Task {
                await registerDeviceToken(fcmToken)
            }
        } else {
            Logger.shared.warning("FCM token is nil", category: "notifications")
        }
    }
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

// MARK: - Supporting Models
struct RegisterDeviceTokenRequest: Codable {
    let token: String
    let deviceType: DeviceType
    let deviceName: String
    let appVersion: String
    let osVersion: String
}

enum DeviceType: String, Codable {
    case ios = "IOS"
    case android = "ANDROID"
}

struct DeviceToken: Codable {
    let id: String
    let token: String
    let deviceType: DeviceType
    let isActive: Bool
    let createdAt: String
    let updatedAt: String?
}

struct EmptyResponse: Codable {}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let fcmTokenReceived = Notification.Name("fcmTokenReceived")
    static let handleNotificationTap = Notification.Name("handleNotificationTap")
    static let navigateToPost = Notification.Name("navigateToPost")
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToMarketplaceItem = Notification.Name("navigateToMarketplaceItem")
    static let navigateToConversation = Notification.Name("navigateToConversation")
    static let memoryWarning = Notification.Name("memoryWarning")
}


