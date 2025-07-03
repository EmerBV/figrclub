//
//  CrashReporter.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import FirebaseCrashlytics

// MARK: - Crash Reporter
final class CrashReporter {
    static let shared = CrashReporter()
    
    private init() {}
    
    func setUserId(_ userId: String) {
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    func setUserEmail(_ email: String) {
        Crashlytics.crashlytics().setCustomValue(email, forKey: "user_email")
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        if let userInfo = userInfo {
            let nsError = NSError(
                domain: error._domain,
                code: error._code,
                userInfo: userInfo
            )
            Crashlytics.crashlytics().record(error: nsError)
        } else {
            Crashlytics.crashlytics().record(error: error)
        }
    }
}
