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
        // API Service
        container.register(APIServiceProtocol.self) { _ in
            APIService()
        }.inObjectScope(.container)
    }
}
