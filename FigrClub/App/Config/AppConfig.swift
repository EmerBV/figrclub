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
    enum Environment {
        case development
        case staging
        case production
        
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
                return "http://localhost:9092/figrclub/api/v1"
            case .staging:
                return "http://localhost:9092/figrclub/api/v1"
            case .production:
                return "http://localhost:9092/figrclub/api/v1"
            }
        }
        
        static let timeout: TimeInterval = 30.0
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Pagination
    struct Pagination {
        static let defaultPageSize = 20
        static let maxPageSize = 100
        static let preloadThreshold = 5 // Load more when 5 items from bottom
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let maxMemoryUsage = 50 * 1024 * 1024 // 50MB
        static let maxImageCacheCount = 100
        static let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    }
    
    // MARK: - Image Configuration
    struct Images {
        static let maxUploadSize = 10 * 1024 * 1024 // 10MB
        static let allowedFormats = ["jpg", "jpeg", "png", "heic"]
        static let compressionQuality: CGFloat = 0.8
        static let maxDimension: CGFloat = 2048
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration: Double = 0.3
        static let hapticFeedbackEnabled = true
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
    }
    
    // MARK: - Security
    struct Security {
        static let keychainService = "com.figrclub.keychain"
        static let biometricEnabled = true
        static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    }
    
    // MARK: - Features
    struct Features {
        static let darkModeEnabled = true
        static let pushNotificationsEnabled = true
        static let analyticsEnabled = true
        static let crashReportingEnabled = true
        static let debugLoggingEnabled = Environment.current != .production
    }
    
    // MARK: - Limits
    struct Limits {
        static let maxPostContentLength = 2000
        static let maxBioLength = 500
        static let maxUsernameLength = 30
        static let minPasswordLength = 8
        static let maxImagesPerPost = 10
    }
    
    // MARK: - URLs
    struct URLs {
        static let privacyPolicy = "https://figrclub.com/privacy"
        static let termsOfService = "https://figrclub.com/terms"
        static let support = "https://figrclub.com/support"
        static let appStore = "https://apps.apple.com/app/figrclub/id123456789"
    }
    
    // MARK: - Social
    struct Social {
        static let twitterURL = "https://twitter.com/figrclub"
        static let instagramURL = "https://instagram.com/figrclub"
        static let discordURL = "https://discord.gg/figrclub"
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
        static var revenueCatAPIKey: String {
            switch Environment.current {
            case .development:
                return "rc_dev_key"
            case .staging:
                return "rc_staging_key"
            case .production:
                return "rc_prod_key"
            }
        }
        
        static var stripePublishableKey: String {
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

// MARK: - Validation Helpers
extension AppConfig.Validation {
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= minPasswordLength && password.count <= maxPasswordLength
    }
    
    static func isValidUsername(_ username: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minUsernameLength && trimmed.count <= maxUsernameLength
    }
    
    static func isValidBio(_ bio: String) -> Bool {
        return bio.count <= maxBioLength
    }
    
    static func isValidPostContent(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxPostContentLength
    }
}

// MARK: - Configuration Validation
extension AppConfig {
    static func validateConfiguration() -> Bool {
        // Validate required configurations
        guard !API.baseURL.isEmpty else {
            fatalError("API base URL is not configured")
        }
        
        guard !Firebase.projectId.isEmpty else {
            fatalError("Firebase project ID is not configured")
        }
        
        guard !AppInfo.bundleId.isEmpty else {
            fatalError("Bundle ID is not configured")
        }
        
        return true
    }
}

// MARK: - Build Configuration
struct BuildConfig {
    static let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "FigrClub"
    static let bundleId = Bundle.main.bundleIdentifier ?? "com.figrclub.app"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    static var fullVersion: String {
        return "\(version) (\(buildNumber))"
    }
    
    static var isDebugBuild: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    static var isTestFlightBuild: Bool {
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }
    
    static var isAppStoreBuild: Bool {
        return !isDebugBuild && !isTestFlightBuild
    }
}
