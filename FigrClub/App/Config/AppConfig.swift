//
//  AppConfig.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

// MARK: - App Configuration
struct AppConfig {
    
    // MARK: - Environment
    enum Environment: String, CaseIterable {
        case development = "dev"
        case staging = "staging"
        case production = "prod"
        
        static var current: Environment {
#if DEBUG
            return .development
#elseif STAGING
            return .staging
#else
            return .production
#endif
        }
    }
    
    // MARK: - API Configuration
    struct API {
        static var baseURL: String {
            switch Environment.current {
            case .development:
                return "https://dev-api.figrclub.com"
            case .staging:
                return "https://staging-api.figrclub.com"
            case .production:
                return "https://api.figrclub.com"
            }
        }
        
        static let timeout: TimeInterval = 30.0
        static let retryLimit = 3
    }
    
    // MARK: - Firebase Configuration
    struct Firebase {
        static var projectId: String {
            switch Environment.current {
            case .development:
                return "figrclub-dev"
            case .staging:
                return "figrclub-staging"
            case .production:
                return "figrclub-prod"
            }
        }
    }
    
    // MARK: - Feature Flags
    struct FeatureFlags {
        static let enableBiometricAuth = true
        static let enablePushNotifications = true
        static let enableAnalytics = Environment.current != .development
        static let enableCrashReporting = Environment.current == .production
        static let showDebugInfo = Environment.current == .development
        static let enableBetaFeatures = Environment.current != .production
    }
    
    // MARK: - App Information
    struct AppInfo {
        static let name = "FigrClub"
        static let bundleId = "com.emerbv.FigrClub"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let minimumOSVersion = "15.0"
    }
    
    // MARK: - Storage Configuration
    struct Storage {
        static let coreDataModelName = "FigrClub"
        static let keychainService = "com.emerbv.FigrClub.keychain"
        static let userDefaultsSuiteName = "group.com.emerbv.FigrClub"
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let imageCacheMemoryLimit = 100 * 1024 * 1024 // 100MB
        static let imageCacheDiskLimit = 200 * 1024 * 1024 // 200MB
        static let imageCacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    }
    
    // MARK: - Pagination
    struct Pagination {
        static let defaultPageSize = 20
        static let maxPageSize = 100
    }
    
    // MARK: - Validation Rules
    struct Validation {
        static let minPasswordLength = 8
        static let maxPasswordLength = 128
        static let minUsernameLength = 3
        static let maxUsernameLength = 30
        static let maxBioLength = 500
        static let maxPostContentLength = 5000
    }
    
    // MARK: - External Services
    struct ExternalServices {
        static let revenueCatAPIKey: String {
            switch Environment.current {
            case .development:
                return "rc_dev_key"
            case .staging:
                return "rc_staging_key"
            case .production:
                return "rc_prod_key"
            }
        }
        
        static let stripePublishableKey: String {
            switch Environment.current {
            case .development:
                return "pk_test_dev"
            case .staging:
                return "pk_test_staging"
            case .production:
                return "pk_live_prod"
            }
        }
    }
    
    // MARK: - Deep Linking
    struct DeepLinking {
        static let scheme = "figrclub"
        static let host = "app"
        
        enum Routes: String, CaseIterable {
            case profile = "/profile"
            case post = "/post"
            case marketplace = "/marketplace"
            case chat = "/chat"
            case notifications = "/notifications"
        }
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let categories: [String] = [
            "LIKE",
            "COMMENT",
            "FOLLOW",
            "NEW_POST",
            "MARKETPLACE_SALE",
            "MARKETPLACE_QUESTION",
            "SYSTEM"
        ]
    }
}

// MARK: - Environment Detection
extension AppConfig.Environment {
    var isDebug: Bool {
        return self == .development
    }
    
    var isProduction: Bool {
        return self == .production
    }
    
    var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}

// MARK: - Debug Information
#if DEBUG
extension AppConfig {
    static func printDebugInfo() {
        print("🏗️ FigrClub Debug Information")
        print("📱 App: \(AppInfo.name) v\(AppInfo.version) (\(AppInfo.buildNumber))")
        print("🌍 Environment: \(Environment.current.displayName)")
        print("🌐 API Base URL: \(API.baseURL)")
        print("🔥 Firebase Project: \(Firebase.projectId)")
        print("🚩 Feature Flags:")
        print("   - Biometric Auth: \(FeatureFlags.enableBiometricAuth)")
        print("   - Push Notifications: \(FeatureFlags.enablePushNotifications)")
        print("   - Analytics: \(FeatureFlags.enableAnalytics)")
        print("   - Crash Reporting: \(FeatureFlags.enableCrashReporting)")
        print("   - Beta Features: \(FeatureFlags.enableBetaFeatures)")
        print("📊 Cache Limits:")
        print("   - Memory: \(Cache.imageCacheMemoryLimit / (1024 * 1024))MB")
        print("   - Disk: \(Cache.imageCacheDiskLimit / (1024 * 1024))MB")
        print("==========================================")
    }
}
#endif
