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
        
        // MARK: - Device Capability Checker
        
        // Device Capability Checker
        container.register(DeviceCapabilityCheckerProtocol.self) { _ in
            return DeviceCapabilityChecker()
        }.inObjectScope(.container)
        
        // MARK: - Manager
        
        // Haptic Feedback Manager - Create on main actor
        container.register(HapticFeedbackManagerProtocol.self) { resolver in
            let deviceCapabilityChecker = resolver.resolve(DeviceCapabilityCheckerProtocol.self)!
            
            // Create on main actor to avoid actor isolation issues
            return MainActor.assumeIsolated {
                return HapticFeedbackManager(
                    deviceCapabilityChecker: deviceCapabilityChecker
                )
            }
        }.inObjectScope(.container)
        
        // Register concrete type for @EnvironmentObject
        container.register(HapticFeedbackManager.self) { resolver in
            // This will be resolved on main actor too
            return resolver.resolve(HapticFeedbackManagerProtocol.self)! as! HapticFeedbackManager
        }.inObjectScope(.container)
        
        Logger.info("✅ HapticFeedbackAssembly: Haptic feedback services registered successfully")
    }
}

