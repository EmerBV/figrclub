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
    
    // MARK: - App Info
    enum AppInfo {
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.figrclub.app"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let appName = "FigrClub"
        static let appStoreId = "1234567890" // Reemplazar con ID real
    }
    
    // MARK: - Environment
    enum Environment {
        static let current: String = {
#if DEBUG
            return "development"
#else
            return "production"
#endif
        }()
        
        static var isDevelopment: Bool {
            current == "development"
        }
        
        static var isProduction: Bool {
            current == "production"
        }
    }
    
    // MARK: - API Configuration
    enum API {
        static let baseURL: String = {
            switch Environment.current {
            case "development":
                return "http://localhost:9092/figrclub/api/v1"
            case "staging":
                return "http://localhost:9092/figrclub/api/v1"
            case "production":
                return "http://localhost:9092/figrclub/api/v1"
            default:
                return "http://localhost:9092/figrclub/api/v1"
            }
        }()
        
        static let timeout: TimeInterval = 30.0
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 1.0
        
        // API Keys
        static let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
        static let googleMapsApiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? ""
    }
    
    // MARK: - Feature Flags
    enum Features {
        static let enableAnalytics = true
        static let enableCrashReporting = !Environment.isDevelopment
        static let pushNotificationsEnabled = true
        static let enableDebugMenu = Environment.isDevelopment
        static let enablePerformanceMonitoring = true
        static let enableOfflineMode = true
        static let enableBiometricAuth = true
        static let enableSocialLogin = true
    }
    
    // MARK: - UI Configuration
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let shadowRadius: CGFloat = 8
        static let animationDuration: TimeInterval = 0.3
        
        // Layout
        static let maxContentWidth: CGFloat = 600
        static let tabBarHeight: CGFloat = 49
        static let navigationBarHeight: CGFloat = 44
        
        // Grid
        static let gridColumns = 2
        static let gridSpacing: CGFloat = 16
        
        // Images
        static let profileImageSize: CGFloat = 100
        static let thumbnailSize: CGFloat = 80
        static let iconSize: CGFloat = 24
    }
    
    // MARK: - Cache Configuration
    enum Cache {
        static let imageCacheMemoryLimit: Int = 100 * 1024 * 1024 // 100 MB
        static let imageCacheDiskLimit: Int = 500 * 1024 * 1024 // 500 MB
        static let imageCacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 días
        static let dataCacheExpiration: TimeInterval = 60 * 60 // 1 hora
        static let userDataCacheExpiration: TimeInterval = 5 * 60 // 5 minutos
    }
    
    // MARK: - Pagination
    enum Pagination {
        static let defaultPageSize = 20
        static let maxPageSize = 100
        static let initialPage = 0
        static let prefetchThreshold = 5
    }
    
    // MARK: - Validation
    enum Validation {
        static let minPasswordLength = 8
        static let maxPasswordLength = 128
        static let minUsernameLength = 3
        static let maxUsernameLength = 20
        static let maxBioLength = 500
        static let maxPostLength = 5000
        static let maxCommentLength = 1000
        static let maxTitleLength = 100
        static let maxHashtagLength = 30
        static let maxHashtagsPerPost = 10
    }
    
    // MARK: - Upload Limits
    enum Upload {
        static let maxImageSize: Int64 = 10 * 1024 * 1024 // 10 MB
        static let maxVideoSize: Int64 = 100 * 1024 * 1024 // 100 MB
        static let maxImagesPerPost = 10
        static let supportedImageFormats = ["jpg", "jpeg", "png", "heic", "heif"]
        static let supportedVideoFormats = ["mp4", "mov", "m4v"]
        static let imageCompressionQuality: CGFloat = 0.8
    }
    
    // MARK: - Security
    enum Security {
        static let keychainServiceName = "com.figrclub.keychain"
        static let pinCodeLength = 6
        static let maxLoginAttempts = 5
        static let lockoutDuration: TimeInterval = 300 // 5 minutos
        static let sessionTimeout: TimeInterval = 3600 // 1 hora
        static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutos antes de expirar
    }
    
    // MARK: - Notifications
    enum Notifications {
        static let lowMemoryWarning = Notification.Name("lowMemoryWarning")
        static let networkStatusChanged = Notification.Name("networkStatusChanged")
        static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    }
    
    // MARK: - Deep Links
    enum DeepLinks {
        static let scheme = "figrclub"
        static let universalLinkDomain = "figrclub.com"
        
        enum Path {
            static let profile = "profile"
            static let post = "post"
            static let marketplace = "marketplace"
            static let notifications = "notifications"
            static let settings = "settings"
        }
    }
    
    // MARK: - Social Media
    enum SocialMedia {
        static let instagramURL = "https://instagram.com/figrclub"
        static let twitterURL = "https://twitter.com/figrclub"
        static let facebookURL = "https://facebook.com/figrclub"
        static let linkedInURL = "https://linkedin.com/company/figrclub"
        static let youtubeURL = "https://youtube.com/figrclub"
    }
    
    // MARK: - Support
    enum Support {
        static let email = "support@figrclub.com"
        static let websiteURL = "https://figrclub.com"
        static let privacyPolicyURL = "https://figrclub.com/privacy"
        static let termsOfServiceURL = "https://figrclub.com/terms"
        static let faqURL = "https://figrclub.com/faq"
    }
}

// MARK: - Debug Configuration
#if DEBUG
enum DebugConfig {
    static let showPerformanceOverlay = false
    static let showNetworkLogs = true
    static let mockAPIResponses = false
    static let forceOnboarding = false
    static let skipAuthentication = false
    static let testUserEmail = "test@figrclub.com"
    static let testUserPassword = "Test1234!"
}
#endif

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
