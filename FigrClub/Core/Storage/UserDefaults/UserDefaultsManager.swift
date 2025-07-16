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
