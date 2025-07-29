//
//  HapticFeedbackAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/7/25.
//

import Foundation
import Swinject

/// Assembly para registrar servicios de feedback háptico
final class HapticFeedbackAssembly: Assembly {
    func assemble(container: Container) {
        Logger.info("🎯 HapticFeedbackAssembly: Registering haptic feedback services...")
        
        // MARK: - Haptic Feedback Service Protocol
        
        /// HapticFeedbackServiceProtocol (Gestión de feedback háptico)
        container.register(HapticFeedbackServiceProtocol.self) { _ in
            return HapticFeedbackService()
        }.inObjectScope(.container)
        
        // MARK: - Concrete HapticFeedbackService
        
        /// Concrete HapticFeedbackService registration for environment objects
        container.register(HapticFeedbackService.self) { resolver in
            return resolver.resolve(HapticFeedbackServiceProtocol.self) as! HapticFeedbackService
        }.inObjectScope(.container)
        
        Logger.info("✅ HapticFeedbackAssembly: Haptic feedback services registered successfully")
    }
} 