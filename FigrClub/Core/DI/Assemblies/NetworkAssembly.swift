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
        // API Configuration
        container.register(APIConfigurationProtocol.self) { _ in
            APIConfiguration()
        }.inObjectScope(.container)
        
        // Network Logger
        container.register(NetworkLoggerProtocol.self) { _ in
            NetworkLogger()
        }.inObjectScope(.container)
        
        // URL Session Provider
        container.register(URLSessionProviderProtocol.self) { r in
            let configuration = r.resolve(APIConfigurationProtocol.self)!
            let logger = r.resolve(NetworkLoggerProtocol.self)!
            return URLSessionProvider(configuration: configuration, logger: logger)
        }.inObjectScope(.container)
        
        // Token Manager
        /*
        container.register(TokenManager.self) { r in
            let secureStorage = r.resolve(SecureStorageProtocol.self)!
            return TokenManager(secureStorage: secureStorage)
        }.inObjectScope(.container)
         */
        
    }
}
