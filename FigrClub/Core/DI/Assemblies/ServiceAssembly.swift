//
//  ServiceAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class ServiceAssembly: Assembly {
    func assemble(container: Container) {
        
        // MARK: - Authentication Services
        
        // Auth Service
        container.register(AuthServiceProtocol.self) { resolver in
            let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
            return AuthService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // MARK: - Validation Services
        
        // Validation Service
        container.register(ValidationServiceProtocol.self) { resolver in
            let localizationManager = resolver.resolve(LocalizationManager.self)!
            
            // Create on MainActor since ValidationService is @MainActor
            return MainActor.assumeIsolated {
                ValidationService(localizationManager: localizationManager)
            }
        }.inObjectScope(.container)
        
        // MARK: - Legal Document Services
        
        // Legal Document Service
        container.register(LegalDocumentServiceProtocol.self) { resolver in
            let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
            return LegalDocumentService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // MARK: - User Services
        
        // User Service (cuando se implemente)
        // container.register(UserServiceProtocol.self) { resolver in
        //     let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
        //     return UserService(networkDispatcher: networkDispatcher)
        // }.inObjectScope(.container)
        
        // MARK: - Content Services
        
        // Post Service (cuando se implemente)
        // container.register(PostServiceProtocol.self) { resolver in
        //     let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
        //     return PostService(networkDispatcher: networkDispatcher)
        // }.inObjectScope(.container)
        
        // Media Service (cuando se implemente)
        // container.register(MediaServiceProtocol.self) { resolver in
        //     let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
        //     return MediaService(networkDispatcher: networkDispatcher)
        // }.inObjectScope(.container)
    }
}
