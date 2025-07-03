//
//  NotificationService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import UIKit
import UserNotifications
import FirebaseMessaging

// MARK: - Notification Service
final class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var fcmToken: String?
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Configuration
    func configure() {
        requestNotificationPermissions()
        registerForRemoteNotifications()
        setupCategories()
    }
    
    // MARK: - Permissions
    func requestNotificationPermissions() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        
        notificationCenter.requestAuthorization(options: options) { granted, error in
            if let error = error {
                Logger.shared.error("Failed to request notification permissions", error: error, category: "notifications")
                return
            }
            
            Logger.shared.info("Notification permissions granted: \(granted)", category: "notifications")
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - Registration
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Categories
    private func setupCategories() {
        // Acciones para notificaciones de posts
        let likeAction = UNNotificationAction(
            identifier: "LIKE_ACTION",
            title: "Me gusta",
            options: []
        )
        
        let commentAction = UNNotificationAction(
            identifier: "COMMENT_ACTION",
            title: "Comentar",
            options: [.foreground]
        )
        
        let postCategory = UNNotificationCategory(
            identifier: "POST_CATEGORY",
            actions: [likeAction, commentAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Acciones para notificaciones de seguimiento
        let followBackAction = UNNotificationAction(
            identifier: "FOLLOW_BACK_ACTION",
            title: "Seguir también",
            options: []
        )
        
        let viewProfileAction = UNNotificationAction(
            identifier: "VIEW_PROFILE_ACTION",
            title: "Ver perfil",
            options: [.foreground]
        )
        
        let followCategory = UNNotificationCategory(
            identifier: "FOLLOW_CATEGORY",
            actions: [followBackAction, viewProfileAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([postCategory, followCategory])
    }
    
    // MARK: - Token Management
    func setFCMToken(_ token: String) {
        self.fcmToken = token
        Logger.shared.info("FCM token set", category: "notifications")
        
        // Enviar token al backend si el usuario está autenticado
        if TokenManager.shared.isAuthenticated {
            Task {
                await registerDeviceToken(token)
            }
        }
    }
    
    private func registerDeviceToken(_ token: String) async {
        do {
            let request = RegisterDeviceTokenRequest(
                token: token,
                platform: "iOS",
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? ""
            )
            
            let _: EmptyResponse = try await APIService.shared
                .request(endpoint: .registerDeviceToken, body: request)
                .async()
            
            Logger.shared.info("Device token registered successfully", category: "notifications")
        } catch {
            Logger.shared.error("Failed to register device token", error: error, category: "notifications")
        }
    }
    
    // MARK: - Badge Management
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func setBadge(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval,
        repeats: Bool = false
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: repeats
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to schedule local notification", error: error, category: "notifications")
            } else {
                Logger.shared.info("Local notification scheduled: \(identifier)", category: "notifications")
            }
        }
    }
    
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostrar notificaciones incluso cuando la app está en primer plano
        completionHandler([.banner, .badge, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Manejar acciones de notificación
        switch response.actionIdentifier {
        case "LIKE_ACTION":
            handleLikeAction(userInfo: userInfo)
        case "COMMENT_ACTION":
            handleCommentAction(userInfo: userInfo)
        case "FOLLOW_BACK_ACTION":
            handleFollowBackAction(userInfo: userInfo)
        case "VIEW_PROFILE_ACTION":
            handleViewProfileAction(userInfo: userInfo)
        case UNNotificationDefaultActionIdentifier:
            handleDefaultAction(userInfo: userInfo)
        default:
            break
        }
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    private func handleLikeAction(userInfo: [AnyHashable: Any]) {
        guard let postId = userInfo["postId"] as? String else { return }
        Logger.shared.info("Like action for post: \(postId)", category: "notifications")
        // Implementar lógica de like
    }
    
    private func handleCommentAction(userInfo: [AnyHashable: Any]) {
        guard let postId = userInfo["postId"] as? String else { return }
        Logger.shared.info("Comment action for post: \(postId)", category: "notifications")
        // Navegar a la pantalla de comentarios
    }
    
    private func handleFollowBackAction(userInfo: [AnyHashable: Any]) {
        guard let userId = userInfo["userId"] as? String else { return }
        Logger.shared.info("Follow back action for user: \(userId)", category: "notifications")
        // Implementar lógica de follow back
    }
    
    private func handleViewProfileAction(userInfo: [AnyHashable: Any]) {
        guard let userId = userInfo["userId"] as? String else { return }
        Logger.shared.info("View profile action for user: \(userId)", category: "notifications")
        // Navegar al perfil del usuario
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        Logger.shared.info("Default notification action", category: "notifications")
        // Manejar acción por defecto
    }
}

// MARK: - Register Device Token Request
struct RegisterDeviceTokenRequest: Codable {
    let token: String
    let platform: String
    let deviceId: String
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


