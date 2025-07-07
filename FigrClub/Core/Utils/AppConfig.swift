//
//  AppConfig.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

// MARK: - App Configuration
enum AppConfig {
    enum API {
        static let baseURL = "http://localhost:9092/figrclub/api/v1"
        static let timeout: TimeInterval = 30
    }
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let animationDuration: Double = 0.3
    }
    
    enum AppInfo {
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    enum Auth {
        static let tokenKey = "auth_token"
        static let userKey = "current_user"
        static let refreshTokenKey = "refresh_token"
    }
}
