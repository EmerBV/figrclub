//
//  FeatureFlagConfiguration.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Feature Flag Configuration
struct FeatureFlagConfiguration {
    let remoteURL: String
    let fallbackFlags: [FeatureFlagKey: Int]
    let refreshInterval: TimeInterval
    let enableLocalStorage: Bool
    let enableBackgroundRefresh: Bool
    
    static let `default` = FeatureFlagConfiguration(
        remoteURL: "https://raw.githubusercontent.com/EmerBV/figrclub-feature-flags/main/main/flags.json",
        fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
        refreshInterval: 300, // 5 minutos
        enableLocalStorage: true,
        enableBackgroundRefresh: true
    )
    
    static let development = FeatureFlagConfiguration(
        remoteURL: "https://raw.githubusercontent.com/EmerBV/figrclub-feature-flags/main/develop/flags.json",
        fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
        refreshInterval: 60, // 1 minuto para desarrollo
        enableLocalStorage: true,
        enableBackgroundRefresh: true
    )
    
    static let testing = FeatureFlagConfiguration(
        remoteURL: "https://raw.githubusercontent.com/EmerBV/figrclub-feature-flags/main/staging/flags.json",
        fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, 1) }), // Todas activadas para testing
        refreshInterval: 30,
        enableLocalStorage: false,
        enableBackgroundRefresh: false
    )
}

// MARK: - Feature Flag Configuration Extension
extension FeatureFlagConfiguration {
    
    /// Get configuration based on current app environment
    static func forCurrentEnvironment() -> FeatureFlagConfiguration {
        let appConfig = AppConfig.shared
        
        switch appConfig.environment {
        case .development:
            return .development
        case .staging:
            return FeatureFlagConfiguration(
                remoteURL: "https://raw.githubusercontent.com/figrclub/feature-flags/staging/flags.json",
                fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
                refreshInterval: 180, // 3 minutos
                enableLocalStorage: true,
                enableBackgroundRefresh: true
            )
        case .production:
            return .default
        }
    }
    
    /// Custom configuration with specific URL
    static func custom(
        remoteURL: String,
        refreshInterval: TimeInterval = 300,
        enableLocalStorage: Bool = true,
        enableBackgroundRefresh: Bool = true
    ) -> FeatureFlagConfiguration {
        return FeatureFlagConfiguration(
            remoteURL: remoteURL,
            fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
            refreshInterval: refreshInterval,
            enableLocalStorage: enableLocalStorage,
            enableBackgroundRefresh: enableBackgroundRefresh
        )
    }
}
