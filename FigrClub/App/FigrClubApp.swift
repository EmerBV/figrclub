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
    // FIXED: No resolvemos AuthManager inmediatamente en @StateObject
    // En su lugar, lo creamos en el body usando una factory method
    
    init() {
        FirebaseApp.configure()
        
        // Aseguramos que el DI esté completamente configurado antes de usarlo
        _ = DependencyInjector.shared
        
        print("🟢 [FigrClubApp.swift] init() - App initialized successfully")
        Logger.info("App initialized successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(createAuthManager())
        }
    }
    
    // MARK: - Helper Methods
    
    /// Factory method para crear AuthManager de forma segura
    private func createAuthManager() -> AuthManager {
        return DependencyInjector.shared.resolve(AuthManager.self)
    }
}
