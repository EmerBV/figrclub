//
//  NotificationCenter+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 1/7/25.
//

import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let showUserAlert = Notification.Name("showUserAlert")
    static let userDataUpdated = Notification.Name("userDataUpdated")
    static let authStateChanged = Notification.Name("authStateChanged")
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
