//
//  NetworkAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

/*
 final class NetworkAssembly: Assembly {
 func assemble(container: Container) {
 
 // Token Manager
 container.register(TokenManager.self) { _ in
 return TokenManager()
 }.inObjectScope(.container)
 
 // APIService (servicio principal)
 container.register(APIService.self) { resolver in
 let tokenManager = resolver.resolve(TokenManager.self)!
 return APIService(tokenManager: tokenManager)
 }.inObjectScope(.container)
 
 // APIServiceProtocol
 container.register(APIServiceProtocol.self) { resolver in
 return resolver.resolve(APIService.self)!
 }.inObjectScope(.container)
 
 // NetworkDispatcherProtocol (para compatibilidad)
 container.register(NetworkDispatcherProtocol.self) { resolver in
 return resolver.resolve(APIService.self)!
 }.inObjectScope(.container)
 
 // Secure Storage
 container.register(SecureStorageProtocol.self) { _ in
 return SecureStorage()
 }.inObjectScope(.container)
 
 // Network Session Configuration
 container.register(URLSession.self) { _ in
 let configuration = URLSessionConfiguration.default
 configuration.timeoutIntervalForRequest = AppConfig.API.timeout
 configuration.timeoutIntervalForResource = AppConfig.API.timeout * 2
 configuration.waitsForConnectivity = true
 configuration.allowsCellularAccess = true
 
 return URLSession(configuration: configuration)
 }.inObjectScope(.container)
 }
 }
 */

// MARK: - Network Assembly
final class NetworkAssembly: Assembly {
    func assemble(container: Container) {
        
        // MARK: - Core Configuration
        
        // API Configuration
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
        
        // URL Session Provider
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
        
        // MARK: - Network Configuration
        
        // URLSession (configured instance)
        container.register(URLSession.self) { resolver in
            let configuration = resolver.resolve(APIConfigurationProtocol.self)!
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = configuration.timeout
            config.timeoutIntervalForResource = configuration.timeout * 2
            config.allowsCellularAccess = configuration.allowsCellularAccess
            config.waitsForConnectivity = configuration.waitsForConnectivity
            
            // Security settings
            config.httpShouldSetCookies = false
            config.httpCookieAcceptPolicy = .never
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            
            return URLSession(configuration: config)
        }.inObjectScope(.container)
    }
}
