//
//  CameraAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/7/25.
//

import Foundation
import Swinject

/// Assembly para registrar servicios de cámara y captura multimedia
final class CameraAssembly: Assembly {
    func assemble(container: Container) {
        Logger.info("📷 CameraAssembly: Registering camera services...")
        
        // MARK: - Camera Manager
        
        /// CameraManager (Gestión de cámara y captura multimedia) - MainActor
        container.register(CameraManager.self) { _ in
            // CameraManager ya está marcado como @MainActor
            return MainActor.assumeIsolated {
                CameraManager()
            }
        }.inObjectScope(.container)
        
        Logger.info("✅ CameraAssembly: Camera services registered successfully")
    }
} 