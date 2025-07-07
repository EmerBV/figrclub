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
        
        // Verificar APIServiceProtocol
        if DependencyInjector.shared.resolveOptional(APIServiceProtocol.self) != nil {
            print("✅ APIServiceProtocol - OK")
        } else {
            print("❌ APIServiceProtocol - FALTANTE")
        }
        
        // Verificar TokenManager
        if DependencyInjector.shared.resolveOptional(TokenManager.self) != nil {
            print("✅ TokenManager - OK")
        } else {
            print("❌ TokenManager - FALTANTE")
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
        
        // Verificar AuthManager
        if DependencyInjector.shared.resolveOptional(AuthManager.self) != nil {
            print("✅ AuthManager - OK")
        } else {
            print("❌ AuthManager - FALTANTE")
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
}

#endif

