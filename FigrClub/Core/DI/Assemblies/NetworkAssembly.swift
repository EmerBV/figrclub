//
//  NetworkAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

// MARK: - Network Assembly
final class NetworkAssembly: Assembly {
    func assemble(container: Container) {
        
        // MARK: - Core Configuration
        
        // API Configuration (Single source of truth)
        container.register(APIConfigurationProtocol.self) { _ in
            return APIConfiguration()
        }.inObjectScope(.container)
        
        // Network Logger
        container.register(NetworkLoggerProtocol.self) { _ in
#if DEBUG
            return NetworkLogger.development()
#else
            return NetworkLogger.production()
#endif
        }.inObjectScope(.container)
        
        // MARK: - Storage Layer
        
        // Token Manager
        container.register(TokenManager.self) { _ in
            return TokenManager()
        }.inObjectScope(.container)
        
        // Secure Storage
        container.register(SecureStorageProtocol.self) { _ in
            return SecureStorage()
        }.inObjectScope(.container)
        
        // User Defaults Manager
        container.register(UserDefaultsManagerProtocol.self) { _ in
            return UserDefaultsManager()
        }.inObjectScope(.container)
        
        // MARK: - Network Layer
        
        // URL Session Provider (uses centralized configuration)
        container.register(URLSessionProviderProtocol.self) { resolver in
            let configuration = resolver.resolve(APIConfigurationProtocol.self)!
            let logger = resolver.resolve(NetworkLoggerProtocol.self)!
            return URLSessionProvider(configuration: configuration, logger: logger)
        }.inObjectScope(.container)
        
        // Network Dispatcher (Primary and Only Network Interface)
        container.register(NetworkDispatcherProtocol.self) { resolver in
            let sessionProvider = resolver.resolve(URLSessionProviderProtocol.self)!
            let tokenManager = resolver.resolve(TokenManager.self)!
            return NetworkDispatcher(sessionProvider: sessionProvider, tokenManager: tokenManager)
        }.inObjectScope(.container)
        
        
        Logger.info("🔧 NetworkAssembly: All network dependencies registered with centralized configuration")
    }
}
