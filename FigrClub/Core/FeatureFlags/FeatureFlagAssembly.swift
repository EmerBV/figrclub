//
//  FeatureFlagAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import Swinject

// MARK: - Feature Flag Assembly
final class FeatureFlagAssembly: Assembly {
    func assemble(container: Container) {
        
        // MARK: - Configuration
        
        // Feature Flag Configuration
        container.register(FeatureFlagConfiguration.self) { _ in
            let appConfig = AppConfig.shared
            
            switch appConfig.environment {
            case .development:
                return FeatureFlagConfiguration.development
            case .staging:
                return FeatureFlagConfiguration.default
            case .production:
                return FeatureFlagConfiguration.default
            }
        }.inObjectScope(.container)
        
        // MARK: - Storage
        
        // Feature Flag Storage
        container.register(FeatureFlagStorageProtocol.self) { _ in
            return FeatureFlagStorage()
        }.inObjectScope(.container)
        
        // MARK: - Service
        
        // Feature Flag Service
        container.register(FeatureFlagServiceProtocol.self) { resolver in
            let configuration = resolver.resolve(FeatureFlagConfiguration.self)!
            let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
            let storage = resolver.resolve(FeatureFlagStorageProtocol.self)!
            
            return FeatureFlagService(
                configuration: configuration,
                networkDispatcher: networkDispatcher,
                storage: storage
            )
        }.inObjectScope(.container)
        
        // MARK: - Manager
        
        // Feature Flag Manager - Create on main actor
        container.register(FeatureFlagManagerProtocol.self) { resolver in
            let service = resolver.resolve(FeatureFlagServiceProtocol.self)!
            let configuration = resolver.resolve(FeatureFlagConfiguration.self)!
            
            // Create on main actor to avoid actor isolation issues
            return MainActor.assumeIsolated {
                return FeatureFlagManager(
                    service: service,
                    configuration: configuration
                )
            }
        }.inObjectScope(.container)
        
        // Register concrete type for @EnvironmentObject
        container.register(FeatureFlagManager.self) { resolver in
            // This will be resolved on main actor too
            return resolver.resolve(FeatureFlagManagerProtocol.self)! as! FeatureFlagManager
        }.inObjectScope(.container)
        
        Logger.info("🚩 FeatureFlagAssembly: All feature flag dependencies registered")
    }
}



// MARK: - DependencyInjector Extension
extension DependencyInjector {
    
    /// Get Feature Flag Manager
    func getFeatureFlagManager() -> FeatureFlagManager {
        return resolve(FeatureFlagManager.self)
    }
    
    /// Get Feature Flag Service
    func getFeatureFlagService() -> FeatureFlagServiceProtocol {
        return resolve(FeatureFlagServiceProtocol.self)
    }
}

