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
        
        // Verificar APIServiceProtocol (UNIFICADO)
        if DependencyInjector.shared.resolveOptional(APIServiceProtocol.self) != nil {
            print("✅ APIServiceProtocol - OK")
        } else {
            print("❌ APIServiceProtocol - FALTANTE")
        }
        
        // Verificar NetworkDispatcherProtocol (ALIAS)
        if DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self) != nil {
            print("✅ NetworkDispatcherProtocol (alias) - OK")
        } else {
            print("❌ NetworkDispatcherProtocol (alias) - FALTANTE")
        }
        
        // Verificar TokenManager
        if DependencyInjector.shared.resolveOptional(TokenManager.self) != nil {
            print("✅ TokenManager - OK")
        } else {
            print("❌ TokenManager - FALTANTE")
        }
        
        // Verificar SecureStorageProtocol
        if DependencyInjector.shared.resolveOptional(SecureStorageProtocol.self) != nil {
            print("✅ SecureStorageProtocol - OK")
        } else {
            print("❌ SecureStorageProtocol - FALTANTE")
        }
        
        // Verificar UserDefaultsManagerProtocol
        if DependencyInjector.shared.resolveOptional(UserDefaultsManagerProtocol.self) != nil {
            print("✅ UserDefaultsManagerProtocol - OK")
        } else {
            print("❌ UserDefaultsManagerProtocol - FALTANTE")
        }
    }
    
    private static func verifyAuthDependencies() {
        print("🔐 [DependencyDebug] Verificando dependencias de autenticación...")
        
        // Verificar ValidationServiceProtocol
        if DependencyInjector.shared.resolveOptional(ValidationServiceProtocol.self) != nil {
            print("✅ ValidationServiceProtocol - OK")
        } else {
            print("❌ ValidationServiceProtocol - FALTANTE")
        }
        
        // Verificar AuthServiceProtocol
        if DependencyInjector.shared.resolveOptional(AuthServiceProtocol.self) != nil {
            print("✅ AuthServiceProtocol - OK")
        } else {
            print("❌ AuthServiceProtocol - FALTANTE")
        }
        
        // Verificar AuthRepositoryProtocol
        if DependencyInjector.shared.resolveOptional(AuthRepositoryProtocol.self) != nil {
            print("✅ AuthRepositoryProtocol - OK")
        } else {
            print("❌ AuthRepositoryProtocol - FALTANTE")
        }
        
        // Verificar AuthStateManager (ACTUALIZADO: AuthManager -> AuthStateManager)
        if DependencyInjector.shared.resolveOptional(AuthStateManager.self) != nil {
            print("✅ AuthStateManager - OK")
        } else {
            print("❌ AuthStateManager - FALTANTE")
        }
    }
    
    private static func verifyViewModelDependencies() {
        print("🎭 [DependencyDebug] Verificando ViewModels...")
        
        // Verificar AuthViewModel
        if DependencyInjector.shared.resolveOptional(AuthViewModel.self) != nil {
            print("✅ AuthViewModel - OK")
        } else {
            print("❌ AuthViewModel - FALTANTE")
        }
    }
    
    // MARK: - Métodos de verificación específicos
    
    /// Verifica que todas las dependencias de autenticación estén correctamente conectadas
    static func verifyAuthFlow() {
        print("🔐 [DependencyDebug] Verificando flujo de autenticación completo...")
        
        // Verificar que podemos crear el flujo completo
        if let authStateManager = DependencyInjector.shared.resolveOptional(AuthStateManager.self),
           let authViewModel = DependencyInjector.shared.resolveOptional(AuthViewModel.self) {
            
            print("✅ Flujo de autenticación verificado correctamente")
            print("   - AuthStateManager: \(type(of: authStateManager))")
            print("   - AuthViewModel: \(type(of: authViewModel))")
            
        } else {
            print("❌ Error en flujo de autenticación: No se pudieron resolver las dependencias")
        }
    }
    
    /// Verifica que todas las dependencias de red estén funcionando
    static func verifyNetworkStack() {
        print("🌐 [DependencyDebug] Verificando stack de red...")
        
        if let tokenManager = DependencyInjector.shared.resolveOptional(TokenManager.self),
           let networkDispatcher = DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self),
           let authService = DependencyInjector.shared.resolveOptional(AuthServiceProtocol.self),
           let secureStorage = DependencyInjector.shared.resolveOptional(SecureStorageProtocol.self) {
            
            print("✅ Stack de red verificado correctamente")
            print("   - TokenManager: \(type(of: tokenManager))")
            print("   - NetworkDispatcher: \(type(of: networkDispatcher))")
            print("   - AuthService: \(type(of: authService))")
            print("   - SecureStorage: \(type(of: secureStorage))")
            
        } else {
            print("❌ Error en stack de red: No se pudieron resolver todas las dependencias")
        }
    }
    
    /// Verifica la configuración completa del contenedor
    static func verifyContainerHealth() {
        print("🏥 [DependencyDebug] Verificando salud del contenedor...")
        
        // Definir tipos de dependencias a verificar
        let dependencyChecks: [(name: String, check: () -> Bool)] = [
            // Core
            ("TokenManager", { DependencyInjector.shared.resolveOptional(TokenManager.self) != nil }),
            ("APIServiceProtocol", { DependencyInjector.shared.resolveOptional(APIServiceProtocol.self) != nil }),
            ("NetworkDispatcherProtocol", { DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self) != nil }),
            ("SecureStorageProtocol", { DependencyInjector.shared.resolveOptional(SecureStorageProtocol.self) != nil }),
            ("UserDefaultsManagerProtocol", { DependencyInjector.shared.resolveOptional(UserDefaultsManagerProtocol.self) != nil }),
            
            // Services
            ("AuthServiceProtocol", { DependencyInjector.shared.resolveOptional(AuthServiceProtocol.self) != nil }),
            ("ValidationServiceProtocol", { DependencyInjector.shared.resolveOptional(ValidationServiceProtocol.self) != nil }),
            
            // Repositories
            ("AuthRepositoryProtocol", { DependencyInjector.shared.resolveOptional(AuthRepositoryProtocol.self) != nil }),
            
            // State Management
            ("AuthStateManager", { DependencyInjector.shared.resolveOptional(AuthStateManager.self) != nil }),
            
            // ViewModels
            ("AuthViewModel", { DependencyInjector.shared.resolveOptional(AuthViewModel.self) != nil })
        ]
        
        var resolvedCount = 0
        var failedDependencies: [String] = []
        
        for dependency in dependencyChecks {
            if dependency.check() {
                resolvedCount += 1
            } else {
                failedDependencies.append(dependency.name)
            }
        }
        
        let totalCount = dependencyChecks.count
        let healthPercentage = (Double(resolvedCount) / Double(totalCount)) * 100
        
        print("📊 Salud del contenedor: \(String(format: "%.1f", healthPercentage))% (\(resolvedCount)/\(totalCount))")
        
        if !failedDependencies.isEmpty {
            print("❌ Dependencias fallidas:")
            for dependency in failedDependencies {
                print("   - \(dependency)")
            }
        }
        
        if healthPercentage == 100 {
            print("🎉 ¡Contenedor completamente saludable!")
        } else if healthPercentage >= 80 {
            print("⚠️ Contenedor mayormente funcional con algunos problemas")
        } else {
            print("🚨 Contenedor con problemas críticos")
        }
    }
}

#endif
