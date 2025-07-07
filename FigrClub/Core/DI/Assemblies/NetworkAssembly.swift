//
//  NetworkAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class NetworkAssembly: Assembly {
    func assemble(container: Container) {
        container.register(TokenManager.self) { _ in
            return TokenManager()
        }.inObjectScope(.container)
        
        // Network Dispatcher
        container.register(NetworkDispatcherProtocol.self) { resolver in
            let tokenManager = resolver.resolve(TokenManager.self)!
            return NetworkDispatcher(tokenManager: tokenManager)
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
            
            // Add request/response interceptors if needed
            return URLSession(configuration: configuration)
        }.inObjectScope(.container)
    }
}
