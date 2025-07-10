//
//  FigrClubApp.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

/*
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
 */

@main
struct FigrClubApp: App {
    
    init() {
        FirebaseApp.configure()
        
        // Asegurar que el DI esté completamente configurado antes de usarlo
        _ = DependencyInjector.shared
        
        print("🟢 [FigrClubApp.swift] initialized successfully")
        Logger.info("🚀 FigrClub initialized networking architecture")
        
#if DEBUG
        // Performance and health checks in debug mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performStartupDiagnostics()
        }
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(createAuthStateManager())
                .onAppear {
#if DEBUG
                    Logger.info("📱 ContentView appeared - App ready for user interaction")
#endif
                }
        }
    }
    
    // MARK: - Factory Methods
    
    private func createAuthStateManager() -> AuthStateManager {
        return DependencyInjector.shared.resolve(AuthStateManager.self)
    }
    
#if DEBUG
    // MARK: - Debug & Diagnostics
    
    private func performStartupDiagnostics() {
        Logger.info("🔍 Performing startup diagnostics...")
        
        // Architecture health check
        performArchitectureHealthCheck()
        
        Logger.info("✅ Startup diagnostics completed - App is ready")
    }
    
    private func performArchitectureHealthCheck() {
        Logger.info("🏥 Performing architecture health check...")
        
        let criticalServices: [(String, Bool)] = [
            ("NetworkDispatcher", DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self) != nil),
            ("AuthStateManager", DependencyInjector.shared.resolveOptional(AuthStateManager.self) != nil),
            ("TokenManager", DependencyInjector.shared.resolveOptional(TokenManager.self) != nil),
            ("AuthService", DependencyInjector.shared.resolveOptional(AuthServiceProtocol.self) != nil),
            ("ValidationService", DependencyInjector.shared.resolveOptional(ValidationServiceProtocol.self) != nil),
            ("SecureStorage", DependencyInjector.shared.resolveOptional(SecureStorageProtocol.self) != nil),
            ("APIService", DependencyInjector.shared.resolveOptional(APIServiceProtocol.self) != nil)
        ]
        
        let healthScore = criticalServices.filter { $0.1 }.count
        let totalServices = criticalServices.count
        
        Logger.info("🏥 Architecture Health: \(healthScore)/\(totalServices) services online")
        
        for (service, isHealthy) in criticalServices {
            Logger.info("  \(isHealthy ? "✅" : "❌") \(service)")
        }
        
        if healthScore == totalServices {
            Logger.info("🎉 Architecture is fully operational!")
        } else {
            Logger.warning("⚠️ Some services are unavailable - check dependency configuration")
        }
    }
#endif
}
