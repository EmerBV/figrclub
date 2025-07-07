//
//  DependencyDebug.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation


#if DEBUG
/// Herramienta de diagnóstico para verificar la configuración de dependencias
final class DependencyDebug {
    
    static func verifyAllDependencies() {
        print("🔍 [DependencyDebug] Verificando dependencias...")
        
        // Verificar dependencias críticas
        verifyCoreDependencies()
        verifyAuthDependencies()
        verifyViewModelDependencies()
        
        print("✅ [DependencyDebug] Verificación completada")
    }
    
    private static func verifyCoreDependencies() {
        print("📦 [DependencyDebug] Verificando dependencias core...")
        
        do {
            let _ = DependencyInjector.shared.resolve(NetworkDispatcherProtocol.self)
            print("✅ NetworkDispatcherProtocol - OK")
        } catch {
            print("❌ NetworkDispatcherProtocol - FALTANTE")
        }
        
        do {
            let _ = DependencyInjector.shared.resolve(APIServiceProtocol.self)
            print("✅ APIServiceProtocol - OK")
        } catch {
            print("❌ APIServiceProtocol - FALTANTE")
        }
        
        do {
            let _ = DependencyInjector.shared.resolve(TokenManager.self)
            print("✅ TokenManager - OK")
        } catch {
            print("❌ TokenManager - FALTANTE")
        }
    }
    
    private static func verifyAuthDependencies() {
        print("🔐 [DependencyDebug] Verificando dependencias de autenticación...")
        
        do {
            let _ = DependencyInjector.shared.resolve(ValidationServiceProtocol.self)
            print("✅ ValidationServiceProtocol - OK")
        } catch {
            print("❌ ValidationServiceProtocol - FALTANTE")
        }
        
        do {
            let _ = DependencyInjector.shared.resolve(AuthServiceProtocol.self)
            print("✅ AuthServiceProtocol - OK")
        } catch {
            print("❌ AuthServiceProtocol - FALTANTE")
        }
        
        do {
            let _ = DependencyInjector.shared.resolve(AuthRepositoryProtocol.self)
            print("✅ AuthRepositoryProtocol - OK")
        } catch {
            print("❌ AuthRepositoryProtocol - FALTANTE")
        }
        
        do {
            let _ = DependencyInjector.shared.resolve(AuthManager.self)
            print("✅ AuthManager - OK")
        } catch {
            print("❌ AuthManager - FALTANTE: \(error)")
        }
    }
    
    private static func verifyViewModelDependencies() {
        print("🎭 [DependencyDebug] Verificando ViewModels...")
        
        do {
            let _ = DependencyInjector.shared.resolve(AuthViewModel.self)
            print("✅ AuthViewModel - OK")
        } catch {
            print("❌ AuthViewModel - FALTANTE: \(error)")
        }
    }
}

/// Extension para debug de AuthManager
extension AuthManager {
    func debugCurrentState() {
        print("🔍 [AuthManager Debug]")
        print("  - AuthState: \(authState)")
        print("  - IsAuthenticated: \(isAuthenticated)")
        print("  - CurrentUser: \(currentUser?.username ?? "nil")")
    }
}
#endif

