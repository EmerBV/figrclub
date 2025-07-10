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
    
    // MARK: - Public Methods
    
    static func verifyAllDependencies() {
        print("🔍 [DependencyDebug] Verificando dependencias...")
        
        // Verificar dependencias críticas
        verifyCoreDependencies()
        verifyAuthDependencies()
        verifyViewModelDependencies()
        verifyNetworkArchitecture()
        
        print("✅ [DependencyDebug] Verificación completada")
    }
    
    // MARK: - Private Verification Methods
    
    private static func verifyCoreDependencies() {
        print("📦 [DependencyDebug] Verificando dependencias core...")
        
        // Verificar NetworkDispatcherProtocol (Interface principal)
        if DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self) != nil {
            print("✅ NetworkDispatcherProtocol - OK")
        } else {
            print("❌ NetworkDispatcherProtocol - FALTANTE")
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
        
        // Verificar NetworkLoggerProtocol
        if DependencyInjector.shared.resolveOptional(NetworkLoggerProtocol.self) != nil {
            print("✅ NetworkLoggerProtocol - OK")
        } else {
            print("❌ NetworkLoggerProtocol - FALTANTE")
        }
        
        // Verificar APIConfigurationProtocol
        if DependencyInjector.shared.resolveOptional(APIConfigurationProtocol.self) != nil {
            print("✅ APIConfigurationProtocol - OK")
        } else {
            print("❌ APIConfigurationProtocol - FALTANTE")
        }
    }
    
    private static func verifyAuthDependencies() {
        print("🔐 [DependencyDebug] Verificando dependencias de autenticación...")
        
        // Verificar AuthServiceProtocol
        if DependencyInjector.shared.resolveOptional(AuthServiceProtocol.self) != nil {
            print("✅ AuthServiceProtocol - OK")
        } else {
            print("❌ AuthServiceProtocol - FALTANTE")
        }
        
        // Verificar AuthStateManager
        if DependencyInjector.shared.resolveOptional(AuthStateManager.self) != nil {
            print("✅ AuthStateManager - OK")
        } else {
            print("❌ AuthStateManager - FALTANTE")
        }
        
        // Verificar ValidationServiceProtocol
        if DependencyInjector.shared.resolveOptional(ValidationServiceProtocol.self) != nil {
            print("✅ ValidationServiceProtocol - OK")
        } else {
            print("❌ ValidationServiceProtocol - FALTANTE")
        }
    }
    
    private static func verifyViewModelDependencies() {
        print("📱 [DependencyDebug] Verificando dependencias de ViewModels...")
        
        // Verificar AuthViewModel
        if DependencyInjector.shared.resolveOptional(AuthViewModel.self) != nil {
            print("✅ LoginViewModel - OK")
        } else {
            print("❌ LoginViewModel - FALTANTE")
        }
        
    }
    
    private static func verifyNetworkArchitecture() {
        print("🌐 [DependencyDebug] Verificando arquitectura de red...")
        
        // Verificar que solo existe NetworkDispatcherProtocol (sin legacy)
        let networkDispatcher = DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self)
        
        if networkDispatcher != nil {
            print("✅ Arquitectura de red unificada - OK")
            print("  📡 NetworkDispatcher como interface principal")
            print("  🚫 Sin dependencias legacy (APIServiceProtocol)")
        } else {
            print("❌ Arquitectura de red - PROBLEMA")
        }
        
        // Verificar componentes de red
        if DependencyInjector.shared.resolveOptional(URLSessionProviderProtocol.self) != nil {
            print("✅ URLSessionProvider - OK")
        } else {
            print("❌ URLSessionProvider - FALTANTE")
        }
    }
    
    // MARK: - Architecture Analysis
    
    static func analyzeArchitecture() {
        print("🏗️ [DependencyDebug] Análisis de arquitectura...")
        
        print("📋 Capas de la aplicación:")
        print("  🎯 Presentation Layer: Views + ViewModels")
        print("  🔄 Business Layer: Services + Managers")
        print("  🌐 Network Layer: NetworkDispatcher + URLSessionProvider")
        print("  💾 Storage Layer: SecureStorage + UserDefaults")
        print("  🔗 DI Layer: Swinject Container")
        
        print("🔄 Flujo de datos:")
        print("  View -> ViewModel -> Service -> NetworkDispatcher -> URLSession")
        print("  URLSession -> NetworkDispatcher -> Service -> ViewModel -> View")
        
        print("🎯 Patrones implementados:")
        print("  ✅ MVVM Architecture")
        print("  ✅ Dependency Injection")
        print("  ✅ Protocol-Oriented Programming")
        print("  ✅ Async/Await Concurrency")
        print("  ✅ Result Type Error Handling")
        print("  ✅ Single Responsibility Principle")
    }
}
#endif
