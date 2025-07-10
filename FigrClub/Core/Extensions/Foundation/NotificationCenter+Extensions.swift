//
//  NotificationCenter+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 1/7/25.
//

import Foundation

// MARK: - Notification Names
extension Notification.Name {
    // User Alerts
    static let showUserAlert = Notification.Name("showUserAlert")
    static let userDataUpdated = Notification.Name("userDataUpdated")
    
    // Authentication
    static let authStateChanged = Notification.Name("authStateChanged")
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let tokenExpired = Notification.Name("tokenExpired")
    static let tokenDidRefresh = Notification.Name("tokenDidRefresh")
    static let tokenRefreshFailed = Notification.Name("tokenRefreshFailed")
    
    // Firebase & Push Notifications
    static let fcmTokenReceived = Notification.Name("fcmTokenReceived")
    static let handleNotificationTap = Notification.Name("handleNotificationTap")
    static let openNotificationSettings = Notification.Name("openNotificationSettings")
    
    // Navigation
    static let navigateToPost = Notification.Name("navigateToPost")
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToMarketplaceItem = Notification.Name("navigateToMarketplaceItem")
    static let navigateToConversation = Notification.Name("navigateToConversation")
    
    // System
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let lowMemoryWarning = Notification.Name("lowMemoryWarning")
    static let memoryWarning = Notification.Name("memoryWarning")
}

// MARK: - User Alert Model
struct UserAlert {
    let title: String
    let message: String
    let type: AlertType
    
    enum AlertType {
        case info
        case warning
        case error
        case success
        
        var systemImageName: String {
            switch self {
            case .info:
                return "info.circle"
            case .warning:
                return "exclamationmark.triangle"
            case .error:
                return "xmark.circle"
            case .success:
                return "checkmark.circle"
            }
        }
        
        var color: String {
            switch self {
            case .info:
                return "blue"
            case .warning:
                return "orange"
            case .error:
                return "red"
            case .success:
                return "green"
            }
        }
    }
}
