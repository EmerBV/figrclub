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
        // Auth Service
        container.register(AuthServiceProtocol.self) { r in
            let apiService = r.resolve(APIServiceProtocol.self)!
            return AuthService(apiService: apiService)
        }.inObjectScope(.container)
        
        // User Service
        container.register(UserServiceProtocol.self) { r in
            let apiService = r.resolve(APIServiceProtocol.self)!
            return UserService(apiService: apiService)
        }.inObjectScope(.container)
        
        // Post Service
        container.register(PostServiceProtocol.self) { r in
            let apiService = r.resolve(APIServiceProtocol.self)!
            return PostService(apiService: apiService)
        }.inObjectScope(.container)
        
        // Marketplace Service
        container.register(MarketplaceServiceProtocol.self) { r in
            let apiService = r.resolve(APIServiceProtocol.self)!
            return MarketplaceService(apiService: apiService)
        }.inObjectScope(.container)
        
        // Notification Service
        container.register(NotificationServiceProtocol.self) { r in
            let apiService = r.resolve(APIServiceProtocol.self)!
            return NotificationService(apiService: apiService)
        }.inObjectScope(.container)
        
        // Category Service
        container.register(CategoryServiceProtocol.self) { r in
            let apiService = r.resolve(APIServiceProtocol.self)!
            return CategoryService(apiService: apiService)
        }.inObjectScope(.container)
    }
}
