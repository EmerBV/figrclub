//
//  UserDefaults+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

extension UserDefaults {
    enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let preferredLanguage = "preferredLanguage"
        static let notificationsEnabled = "notificationsEnabled"
        static let lastSyncDate = "lastSyncDate"
    }
    
    var hasSeenOnboarding: Bool {
        get { bool(forKey: Keys.hasSeenOnboarding) }
        set { set(newValue, forKey: Keys.hasSeenOnboarding) }
    }
    
    var preferredLanguage: String? {
        get { string(forKey: Keys.preferredLanguage) }
        set { set(newValue, forKey: Keys.preferredLanguage) }
    }
    
    var notificationsEnabled: Bool {
        get { bool(forKey: Keys.notificationsEnabled) }
        set { set(newValue, forKey: Keys.notificationsEnabled) }
    }
    
    var lastSyncDate: Date? {
        get { object(forKey: Keys.lastSyncDate) as? Date }
        set { set(newValue, forKey: Keys.lastSyncDate) }
    }
}
