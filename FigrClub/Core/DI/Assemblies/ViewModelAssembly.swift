//
//  ViewModelAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class ViewModelAssembly: Assembly {
    func assemble(container: Container) {
        // Input Validator (si no está registrado en otros assemblies)
        container.register(InputValidatorProtocol.self) { _ in
            InputValidator()
        }.inObjectScope(.container)
        
        // Navigation Coordinator (si lo usas)
        container.register(NavigationCoordinatorProtocol.self) { r in
            NavigationCoordinator(dependencyInjector: r as! DependencyInjector)
        }.inObjectScope(.container)
        
        // Generic ViewModels que no encajan en categorías específicas
        // pueden ir aquí o ser movidos a sus assemblies correspondientes
    }
}
