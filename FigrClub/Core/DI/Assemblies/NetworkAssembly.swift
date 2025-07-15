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
        
        // MARK: - Enhanced Network Layer Components
        
        // Network Cache
        container.register(NetworkCacheProtocol.self) { _ in
            return NetworkCache(maxMemorySize: 50 * 1024 * 1024, defaultMaxAge: 300) // 50MB, 5min default
        }.inObjectScope(.container)
        
        // Network Analytics Service
        container.register(NetworkAnalyticsServiceProtocol.self) { _ in
            return NetworkAnalyticsService()
        }.inObjectScope(.container)
        
        // ETag Manager
        container.register(ETagManagerProtocol.self) { resolver in
            let cache = resolver.resolve(NetworkCacheProtocol.self)!
            return ETagManager(cache: cache)
        }.inObjectScope(.container)
        
        // Retry Policy Manager
        container.register(RetryPolicyManager.self) { _ in
            return RetryPolicyManager()
        }.inObjectScope(.container)
        
        // Circuit Breaker Manager
        container.register(CircuitBreakerManager.self) { _ in
            return CircuitBreakerManager()
        }.inObjectScope(.container)
        
        // Network Connectivity Monitor
        container.register(NetworkConnectivityMonitor.self) { _ in
            return NetworkConnectivityMonitor()
        }.inObjectScope(.container)
        
        // Offline Request Queue
        container.register(OfflineRequestQueue.self) { resolver in
            let networkMonitor = resolver.resolve(NetworkConnectivityMonitor.self)!
            return OfflineRequestQueue(networkMonitor: networkMonitor)
        }.inObjectScope(.container)
        
        // Background Refresh Manager
        container.register(BackgroundRefreshManager.self) { resolver in
            let cache = resolver.resolve(NetworkCacheProtocol.self)!
            let dispatcher = resolver.resolve(NetworkDispatcher.self)!
            return BackgroundRefreshManager(cache: cache, networkDispatcher: dispatcher)
        }.inObjectScope(.container)
        
        // Network Dispatcher (Primary and Only Network Interface)
        container.register(NetworkDispatcherProtocol.self) { resolver in
            let sessionProvider = resolver.resolve(URLSessionProviderProtocol.self)!
            let tokenManager = resolver.resolve(TokenManager.self)!
            let dispatcher = NetworkDispatcher(sessionProvider: sessionProvider, tokenManager: tokenManager)
            
            return dispatcher
        }.inObjectScope(.container)
        
        // Convenience accessor for NetworkDispatcher
        container.register(NetworkDispatcher.self) { resolver in
            return resolver.resolve(NetworkDispatcherProtocol.self) as! NetworkDispatcher
        }.inObjectScope(.container)
        
        Logger.info("🔧 NetworkAssembly: Enhanced network layer with all optimizations registered")
    }
}
