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
    }
}
