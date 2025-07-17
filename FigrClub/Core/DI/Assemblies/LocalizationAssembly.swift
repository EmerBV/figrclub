//
//  LocalizationAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import Foundation
import Swinject

final class LocalizationAssembly: Assembly {
    func assemble(container: Container) {
        
        // MARK: - Localization Manager
        
        // LocalizationManager (Centralized localization management) - MainActor
        container.register(LocalizationManagerProtocol.self) { _ in
            // Create on MainActor
            return MainActor.assumeIsolated {
                LocalizationManager()
            }
        }.inObjectScope(.container)
        
        // Concrete implementation for cases where we need the specific type
        container.register(LocalizationManager.self) { resolver in
            return resolver.resolve(LocalizationManagerProtocol.self) as! LocalizationManager
        }.inObjectScope(.container)
        
        Logger.debug("✅ LocalizationAssembly: Localization services registered")
    }
} 