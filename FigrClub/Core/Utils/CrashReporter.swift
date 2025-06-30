//
//  CrashReporter.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

// MARK: - Crash Reporter
final class CrashReporter {
    static let shared = CrashReporter()
    
    private init() {}
    
    func configure() {
        guard AppConfig.FeatureFlags.enableCrashReporting else { return }
        
        // Set user identifier for crash reports
        if let userId = TokenManager.shared.getUserId() {
            Crashlytics.crashlytics().setUserID(String(userId))
        }
        
        // Set custom keys
        Crashlytics.crashlytics().setCustomValue(AppConfig.AppInfo.version, forKey: "app_version")
        Crashlytics.crashlytics().setCustomValue(AppConfig.AppInfo.buildNumber, forKey: "build_number")
        Crashlytics.crashlytics().setCustomValue(AppConfig.Environment.current.rawValue, forKey: "environment")
    }
    
    func setUserId(_ userId: String) {
        guard AppConfig.FeatureFlags.enableCrashReporting else { return }
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    func setUserEmail(_ email: String) {
        guard AppConfig.FeatureFlags.enableCrashReporting else { return }
        Crashlytics.crashlytics().setCustomValue(email, forKey: "user_email")
    }
    
    func recordError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        guard AppConfig.FeatureFlags.enableCrashReporting else { return }
        
        // Add additional info as custom keys
        if let additionalInfo = additionalInfo {
            for (key, value) in additionalInfo {
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
        
        Crashlytics.crashlytics().record(error: error)
    }
    
    func log(_ message: String) {
        guard AppConfig.FeatureFlags.enableCrashReporting else { return }
        Crashlytics.crashlytics().log(message)
    }
    
    func recordNonFatalError(_ error: Error, context: String) {
        guard AppConfig.FeatureFlags.enableCrashReporting else { return }
        
        Crashlytics.crashlytics().setCustomValue(context, forKey: "error_context")
        Crashlytics.crashlytics().record(error: error)
        
        Logger.shared.error("Non-fatal error in \(context)", error: error, category: "crash_reporter")
    }
}
