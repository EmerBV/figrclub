//
//  ThemeAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 22/7/25.
//

import Foundation
import Swinject

// MARK: - Theme Assembly
struct ThemeAssembly: Assembly {
    
    func assemble(container: Container) {
        Logger.info("🎨 ThemeAssembly: Registering theme services...")
        
        // MARK: - ThemeManager Registration
        container.register(ThemeManager.self) { _ in
            return ThemeManager()
        }
        .inObjectScope(.container) // Singleton scope - una instancia para toda la app
        
        Logger.info("✅ ThemeAssembly: Theme services registered successfully")
    }
}
