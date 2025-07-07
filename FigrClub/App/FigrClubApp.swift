//
//  FigrClubApp.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct FigrClubApp: App {
    
    init() {
        FirebaseApp.configure()
        
        // Aseguramos que el DI esté completamente configurado antes de usarlo
        _ = DependencyInjector.shared
        
        print("🟢 [FigrClubApp.swift] init() - App initialized successfully")
        Logger.info("App initialized successfully")
        
        #if DEBUG
        // En debug, mostrar información del contenedor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DependencyDebug.verifyContainerHealth()
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(createAuthStateManager())
        }
    }
    
    // MARK: - Helper Methods
    
    /// Factory method para crear AuthStateManager de forma segura
    private func createAuthStateManager() -> AuthStateManager {
        return DependencyInjector.shared.resolve(AuthStateManager.self)
    }
}
