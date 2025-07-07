//
//  UserDefaultsManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol UserDefaultsManagerProtocol {
    func save(value: Any, forKey key: String)
    func getString(forKey key: String) -> String?
    func getBool(forKey key: String) -> Bool
    func getInt(forKey key: String) -> Int
    func remove(forKey key: String)
}

final class UserDefaultsManager: UserDefaultsManagerProtocol {
    private let userDefaults = UserDefaults.standard
    
    func save(value: Any, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func getBool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    func getInt(forKey key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}

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
