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
