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
        container.register(AuthServiceProtocol.self) { resolver in
            let networkDispatcher = resolver.resolve(NetworkDispatcherProtocol.self)!
            return AuthService(networkDispatcher: networkDispatcher)
        }.inObjectScope(.container)
        
        // Validation Service
        container.register(ValidationServiceProtocol.self) { _ in
            return ValidationService()
        }.inObjectScope(.container)
    }
}
