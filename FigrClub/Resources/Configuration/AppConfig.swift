//
//  AppConfig.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import UIKit

// MARK: - App Environment
enum AppEnvironment: String, CaseIterable {
    case development
    case staging
    case production
    
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
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:9092/figrclub/api/v1"
        case .staging:
            return "https://staging-api.figrclub.com/api/v1"
        case .production:
            return "https://api.figrclub.com/api/v1"
        }
    }
    
    var imageBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:9092/figrclub/images"
        case .staging:
            return "https://staging-images.figrclub.com"
        case .production:
            return "https://images.figrclub.com"
        }
    }
    
    var timeout: TimeInterval {
        switch self {
        case .development:
            return 60.0  // Tiempo más largo para desarrollo (debugging)
        case .staging:
            return 30.0
        case .production:
            return 15.0  // Más corto en producción para mejor UX
        }
    }
    
    var isDebugEnvironment: Bool {
        switch self {
        case .development:
            return true
        case .staging:
            return true
        case .production:
            return false
        }
    }
}

// MARK: - App Configuration
final class AppConfig {
    
    // MARK: - Singleton
    static let shared = AppConfig()
    
    // MARK: - Configuration Properties
    private(set) var environment: AppEnvironment
    private(set) var appName: String
    private(set) var appVersion: String
    private(set) var buildNumber: String
    private(set) var bundleIdentifier: String
    private(set) var apiBaseURL: String
    private(set) var imageBaseURL: String
    private(set) var apiTimeout: TimeInterval
    
    // MARK: - Feature Flags
    private(set) var enableAnalytics: Bool
    private(set) var enableCrashReporting: Bool
    private(set) var enableDebugLogging: Bool
    private(set) var enableNetworkLogging: Bool
    private(set) var enableBiometricAuth: Bool
    private(set) var enablePushNotifications: Bool
    
    // MARK: - FigrClub Specific Settings
    private(set) var maxPhotosPerPost: Int
    private(set) var maxVideoLength: TimeInterval
    private(set) var supportedImageFormats: [String]
    private(set) var supportedVideoFormats: [String]
    private(set) var maxFileSize: Int // in MB
    
    // MARK: - Initialization
    private init() {
        // Environment configuration based on build type
#if DEBUG
        self.environment = .development
        self.enableDebugLogging = true
        self.enableNetworkLogging = true
        self.enableAnalytics = false
        self.enableCrashReporting = false
#elseif STAGING
        self.environment = .staging
        self.enableDebugLogging = true
        self.enableNetworkLogging = false
        self.enableAnalytics = true
        self.enableCrashReporting = true
#else
        self.environment = .production
        self.enableDebugLogging = false
        self.enableNetworkLogging = false
        self.enableAnalytics = true
        self.enableCrashReporting = true
#endif
        
        // Bundle information
        let bundle = Bundle.main
        self.appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "FigrClub"
        self.appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        self.buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        self.bundleIdentifier = bundle.bundleIdentifier ?? "com.emerbv.FigrClub"
        
        // API Configuration
        self.apiBaseURL = environment.baseURL
        self.imageBaseURL = environment.imageBaseURL
        self.apiTimeout = environment.timeout
        
        // Feature flags (can be overridden later)
        self.enableBiometricAuth = true
        self.enablePushNotifications = true
        
        // FigrClub specific settings
        self.maxPhotosPerPost = 10
        self.maxVideoLength = 60.0 // 1 minute
        self.supportedImageFormats = ["jpg", "jpeg", "png", "heic", "webp"]
        self.supportedVideoFormats = ["mp4", "mov", "avi"]
        self.maxFileSize = 50 // 50MB
        
        // Log configuration if debug logging is enabled
        if enableDebugLogging {
            logConfiguration()
        }
        
        // Setup additional configurations
        setupAdditionalConfigurations()
    }
    
    // MARK: - Configuration Logging
    private func logConfiguration() {
        Logger.info("🏗️ FigrClub Configuration:")
        Logger.info("  📱 App: \(appName) v\(appVersion) (\(buildNumber))")
        Logger.info("  🌍 Environment: \(environment.displayName)")
        Logger.info("  🔗 API URL: \(apiBaseURL)")
        Logger.info("  🖼️ Images URL: \(imageBaseURL)")
        Logger.info("  ⏱️ Timeout: \(apiTimeout)s")
        Logger.info("  📊 Analytics: \(enableAnalytics ? "Enabled" : "Disabled")")
        Logger.info("  💥 Crash Reporting: \(enableCrashReporting ? "Enabled" : "Disabled")")
        Logger.info("  🔍 Debug Logging: \(enableDebugLogging ? "Enabled" : "Disabled")")
        Logger.info("  🌐 Network Logging: \(enableNetworkLogging ? "Enabled" : "Disabled")")
        Logger.info("  🔐 Biometric Auth: \(enableBiometricAuth ? "Enabled" : "Disabled")")
        Logger.info("  📮 Push Notifications: \(enablePushNotifications ? "Enabled" : "Disabled")")
        Logger.info("  📸 Max Photos/Post: \(maxPhotosPerPost)")
        Logger.info("  🎬 Max Video Length: \(maxVideoLength)s")
        Logger.info("  💾 Max File Size: \(maxFileSize)MB")
    }
    
    // MARK: - Additional Setup
    private func setupAdditionalConfigurations() {
        // Configure app-specific settings
        setupSecuritySettings()
        setupNetworkSettings()
    }
    
    private func setupSecuritySettings() {
        // Configure security settings based on environment
        if environment.isDebugEnvironment {
            // Allow more permissive settings for debugging
            Logger.debug("🔐 Security: Debug mode - permissive settings enabled")
        } else {
            // Strict security for production
            Logger.info("🔐 Security: Production mode - strict settings enabled")
        }
    }
    
    private func setupNetworkSettings() {
        // Configure network-specific settings
        if enableNetworkLogging {
            Logger.debug("🌐 Network: Detailed logging enabled")
        }
    }
}

// MARK: - Environment Management
extension AppConfig {
    
    /// Change environment at runtime (useful for testing or debugging)
    func setEnvironment(_ env: AppEnvironment) {
        environment = env
        apiBaseURL = env.baseURL
        imageBaseURL = env.imageBaseURL
        apiTimeout = env.timeout
        
        Logger.info("🔄 Environment changed to: \(env.displayName)")
        Logger.info("  🔗 API URL: \(apiBaseURL)")
        Logger.info("  🖼️ Images URL: \(imageBaseURL)")
        Logger.info("  ⏱️ Timeout: \(apiTimeout)s")
    }
    
    /// Get all available environments
    var availableEnvironments: [AppEnvironment] {
        return AppEnvironment.allCases
    }
}

// MARK: - Feature Flag Management
extension AppConfig {
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        enableAnalytics = enabled
        Logger.info("📊 Analytics: \(enabled ? "Enabled" : "Disabled")")
    }
    
    func setCrashReportingEnabled(_ enabled: Bool) {
        enableCrashReporting = enabled
        Logger.info("💥 Crash Reporting: \(enabled ? "Enabled" : "Disabled")")
    }
    
    func setDebugLoggingEnabled(_ enabled: Bool) {
        enableDebugLogging = enabled
        Logger.info("🔍 Debug Logging: \(enabled ? "Enabled" : "Disabled")")
    }
    
    func setNetworkLoggingEnabled(_ enabled: Bool) {
        enableNetworkLogging = enabled
        Logger.info("🌐 Network Logging: \(enabled ? "Enabled" : "Disabled")")
    }
    
    func setBiometricAuthEnabled(_ enabled: Bool) {
        enableBiometricAuth = enabled
        Logger.info("🔐 Biometric Auth: \(enabled ? "Enabled" : "Disabled")")
    }
    
    func setPushNotificationsEnabled(_ enabled: Bool) {
        enablePushNotifications = enabled
        Logger.info("📮 Push Notifications: \(enabled ? "Enabled" : "Disabled")")
    }
}

// MARK: - Media Configuration
extension AppConfig {
    
    func setMaxPhotosPerPost(_ count: Int) {
        maxPhotosPerPost = max(1, min(count, 20)) // Entre 1 y 20
        Logger.info("📸 Max Photos/Post updated to: \(maxPhotosPerPost)")
    }
    
    func setMaxVideoLength(_ seconds: TimeInterval) {
        maxVideoLength = max(15, min(seconds, 300)) // Entre 15s y 5min
        Logger.info("🎬 Max Video Length updated to: \(maxVideoLength)s")
    }
    
    func setMaxFileSize(_ sizeMB: Int) {
        maxFileSize = max(5, min(sizeMB, 100)) // Entre 5MB y 100MB
        Logger.info("💾 Max File Size updated to: \(maxFileSize)MB")
    }
    
    func isImageFormatSupported(_ format: String) -> Bool {
        return supportedImageFormats.contains(format.lowercased())
    }
    
    func isVideoFormatSupported(_ format: String) -> Bool {
        return supportedVideoFormats.contains(format.lowercased())
    }
}

// MARK: - Network Headers
extension AppConfig {
    
    /// Generate User-Agent for HTTP requests
    func getUserAgent() -> String {
        let device = UIDevice.current
        let osVersion = device.systemVersion
        let deviceModel = device.model
        
        return "\(appName)/\(appVersion) (\(buildNumber); \(deviceModel); iOS \(osVersion))"
    }
    
    /// Get default headers for API requests
    func getDefaultHeaders() -> [String: String] {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": getUserAgent(),
            "X-App-Version": appVersion,
            "X-Build-Number": buildNumber,
            "X-Environment": environment.rawValue
        ]
    }
}

// MARK: - Legacy enums removed - use AppConfig.shared directly

// MARK: - Debug Information
#if DEBUG
extension AppConfig {
    
    /// Print detailed debug information
    func printDebugInfo() {
        print("""
        
        🏗️ ===== FigrClub Configuration Debug =====
        📱 App Information:
           • Name: \(appName)
           • Version: \(appVersion)
           • Build: \(buildNumber)
           • Bundle ID: \(bundleIdentifier)
        
        🌍 Environment: \(environment.displayName)
           • API Base URL: \(apiBaseURL)
           • Images Base URL: \(imageBaseURL)
           • Timeout: \(apiTimeout)s
           • Is Debug: \(environment.isDebugEnvironment)
        
        🎛️ Feature Flags:
           • Analytics: \(enableAnalytics ? "✅" : "❌")
           • Crash Reporting: \(enableCrashReporting ? "✅" : "❌")
           • Debug Logging: \(enableDebugLogging ? "✅" : "❌")
           • Network Logging: \(enableNetworkLogging ? "✅" : "❌")
           • Biometric Auth: \(enableBiometricAuth ? "✅" : "❌")
           • Push Notifications: \(enablePushNotifications ? "✅" : "❌")
        
        📸 Media Settings:
           • Max Photos/Post: \(maxPhotosPerPost)
           • Max Video Length: \(maxVideoLength)s
           • Max File Size: \(maxFileSize)MB
           • Image Formats: \(supportedImageFormats.joined(separator: ", "))
           • Video Formats: \(supportedVideoFormats.joined(separator: ", "))
        
        🌐 Network:
           • User Agent: \(getUserAgent())
        ========================================
        
        """)
    }
}
#endif
