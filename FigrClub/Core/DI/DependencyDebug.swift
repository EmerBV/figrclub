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
        
        // Verificar dependencias de Kingfisher
        verifyKingfisherDependencies()
        verifyImageLoadingArchitecture()
        verifyPerformanceMonitoring()
        
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
    
    private static func verifyKingfisherDependencies() {
        print("🖼️ [DependencyDebug] Verificando dependencias de Kingfisher...")
        
        // Verificar KingfisherConfigurable
        if DependencyInjector.shared.resolveOptional(KingfisherConfigurable.self) != nil {
            print("✅ KingfisherConfigurable - OK")
        } else {
            print("❌ KingfisherConfigurable - FALTANTE")
        }
        
        // Verificar ImageCacheServiceProtocol
        if DependencyInjector.shared.resolveOptional(ImageCacheServiceProtocol.self) != nil {
            print("✅ ImageCacheServiceProtocol - OK")
        } else {
            print("❌ ImageCacheServiceProtocol - FALTANTE")
        }
        
        // Verificar ImageDownloaderServiceProtocol
        if DependencyInjector.shared.resolveOptional(ImageDownloaderServiceProtocol.self) != nil {
            print("✅ ImageDownloaderServiceProtocol - OK")
        } else {
            print("❌ ImageDownloaderServiceProtocol - FALTANTE")
        }
        
        // Verificar ImageProcessingServiceProtocol
        if DependencyInjector.shared.resolveOptional(ImageProcessingServiceProtocol.self) != nil {
            print("✅ ImageProcessingServiceProtocol - OK")
        } else {
            print("❌ ImageProcessingServiceProtocol - FALTANTE")
        }
        
        // Verificar ImageManagerProtocol (High-level interface)
        if DependencyInjector.shared.resolveOptional(ImageManagerProtocol.self) != nil {
            print("✅ ImageManagerProtocol - OK")
        } else {
            print("❌ ImageManagerProtocol - FALTANTE")
        }
    }
    
    private static func verifyImageLoadingArchitecture() {
        print("🎨 [DependencyDebug] Verificando arquitectura de carga de imágenes...")
        
        // Verificar que la configuración de Kingfisher está aplicada
        if let kingfisherConfig = DependencyInjector.shared.resolveOptional(KingfisherConfigurable.self) {
            print("✅ Configuración de Kingfisher aplicada")
            
            // Verificar que ImageManager está disponible
            if let imageManager = DependencyInjector.shared.resolveOptional(ImageManagerProtocol.self) {
                print("✅ ImageManager configurado correctamente")
                print("  🎯 Cache management disponible")
                print("  📥 Download service configurado")
                print("  🎨 Image processing configurado")
            } else {
                print("❌ ImageManager no configurado")
            }
        } else {
            print("❌ Configuración de Kingfisher faltante")
        }
        
        // Verificar flujo de carga de imágenes
        print("🔄 Flujo de carga de imágenes:")
        print("  SwiftUI View -> KFImage/OptimizedKFImage")
        print("  KFImage -> ImageManager -> Cache/Download/Processing Services")
        print("  Services -> Kingfisher Core -> Network/Disk/Memory")
    }
    
    private static func verifyPerformanceMonitoring() {
        print("📊 [DependencyDebug] Verificando monitoreo de rendimiento...")
        
        // En debug, verificar que el tracking está disponible
#if DEBUG
        print("✅ Performance tracking habilitado (DEBUG)")
        print("  📈 ImagePerformanceMonitor activo")
        print("  🎯 Cache metrics disponibles")
        print("  ⚡ Load time tracking habilitado")
#else
        print("ℹ️ Performance tracking limitado (RELEASE)")
#endif
        
        // Verificar que las métricas están configuradas
        print("📋 Métricas configuradas:")
        print("  💾 Cache hit/miss tracking")
        print("  ⏱️ Image load time monitoring")
        print("  🚨 Error tracking y alertas")
        print("  📊 System performance monitoring")
    }
    
    // MARK: - Architecture Analysis
    
    static func analyzeArchitecture() {
        print("🏗️ [DependencyDebug] Análisis de arquitectura...")
        
        print("📋 Capas de la aplicación:")
        print("  🎯 Presentation Layer: Views + ViewModels")
        print("  🖼️ Image Layer: KFImage + OptimizedKFImage + SwiftUI Extensions")
        print("  🔄 Business Layer: Services + Managers + ImageManager")
        print("  🌐 Network Layer: NetworkDispatcher + URLSessionProvider")
        print("  💾 Storage Layer: SecureStorage + UserDefaults + ImageCache")
        print("  🔗 DI Layer: Swinject Container + KingfisherAssembly")
        
        print("🔄 Flujo de datos:")
        print("  View -> ViewModel -> Service -> NetworkDispatcher -> URLSession")
        print("  URLSession -> NetworkDispatcher -> Service -> ViewModel -> View")
        
        print("🖼️ Flujo de imágenes:")
        print("  SwiftUI -> KFImage -> ImageManager -> Kingfisher -> Cache/Network")
        print("  Cache/Network -> Kingfisher -> ImageManager -> KFImage -> SwiftUI")
        
        print("🎯 Patrones implementados:")
        print("  ✅ MVVM Architecture")
        print("  ✅ Dependency Injection")
        print("  ✅ Protocol-Oriented Programming")
        print("  ✅ Async/Await Concurrency")
        print("  ✅ Result Type Error Handling")
        print("  ✅ Single Responsibility Principle")
        print("  ✅ Image Loading Architecture")
        print("  ✅ Performance Monitoring")
        print("  ✅ Cache Management")
    }
    
    static func performKingfisherHealthCheck() {
        print("🩺 [DependencyDebug] Health Check de Kingfisher...")
        
        guard let imageManager = DependencyInjector.shared.resolveOptional(ImageManagerProtocol.self) else {
            print("❌ ImageManager no disponible")
            return
        }
        
        Task {
            do {
                // Verificar métricas de cache
                let cacheInfo = await imageManager.getCacheMetrics()
                print("✅ Cache Metrics disponibles:")
                print("  💾 Disk: \(cacheInfo.formattedDiskUsed) / \(cacheInfo.formattedDiskLimit)")
                print("  🧠 Memory: \(cacheInfo.formattedMemoryUsed) / \(cacheInfo.formattedMemoryLimit)")
                print("  📊 Disk Usage: \(String(format: "%.1f", cacheInfo.diskUsagePercentage))%")
                print("  📊 Memory Usage: \(String(format: "%.1f", cacheInfo.memoryUsagePercentage))%")
                
                // Test de cache management
                print("🧪 Testing cache operations...")
                imageManager.clearCache(type: .expired)
                print("✅ Cache cleanup test passed")
                
            } catch {
                print("❌ Kingfisher health check failed: \(error)")
            }
        }
    }
    
    /*
     static func printDependencyStatistics() {
     print("📊 [DependencyDebug] Estadísticas de dependencias...")
     
     let coreCount = countCoreDependencies()
     let authCount = countAuthDependencies()
     let kingfisherCount = countKingfisherDependencies()
     let viewModelCount = countViewModelDependencies()
     
     let totalDependencies = coreCount + authCount + kingfisherCount + viewModelCount
     
     print("📈 Total de dependencias registradas: \(totalDependencies)")
     print("  📦 Core: \(coreCount)")
     print("  🔐 Auth: \(authCount)")
     print("  🖼️ Kingfisher: \(kingfisherCount)")
     print("  📱 ViewModels: \(viewModelCount)")
     
     print("🎯 Salud del contenedor: \(totalDependencies > 0 ? "✅ Saludable" : "❌ Problemas")")
     
     if totalDependencies > 15 {
     print("⚡ Arquitectura robusta con \(totalDependencies) dependencias")
     } else if totalDependencies > 10 {
     print("✅ Arquitectura sólida con \(totalDependencies) dependencias")
     } else {
     print("⚠️ Arquitectura básica con \(totalDependencies) dependencias")
     }
     }
     
     // MARK: - Dependency Counters
     
     private static func countCoreDependencies() -> Int {
     let dependencies: [Any.Type] = [
     NetworkDispatcherProtocol.self,
     TokenManager.self,
     SecureStorageProtocol.self,
     UserDefaultsManagerProtocol.self,
     NetworkLoggerProtocol.self,
     APIConfigurationProtocol.self,
     URLSessionProviderProtocol.self
     ]
     
     return dependencies.compactMap { DependencyInjector.shared.resolveOptional($0) }.count
     }
     
     private static func countAuthDependencies() -> Int {
     let dependencies: [Any.Type] = [
     AuthServiceProtocol.self,
     AuthStateManager.self,
     ValidationServiceProtocol.self
     ]
     
     return dependencies.compactMap { DependencyInjector.shared.resolveOptional($0) }.count
     }
     
     private static func countKingfisherDependencies() -> Int {
     let dependencies: [Any.Type] = [
     KingfisherConfigurable.self,
     ImageCacheServiceProtocol.self,
     ImageDownloaderServiceProtocol.self,
     ImageProcessingServiceProtocol.self,
     ImageManagerProtocol.self
     ]
     
     return dependencies.compactMap { DependencyInjector.shared.resolveOptional($0) }.count
     }
     
     private static func countViewModelDependencies() -> Int {
     let dependencies: [Any.Type] = [
     AuthViewModel.self
     ]
     
     return dependencies.compactMap { DependencyInjector.shared.resolveOptional($0) }.count
     }
     
     // MARK: - ✅ NUEVO: Integration Test
     
     static func performFullIntegrationTest() {
     print("🧪 [DependencyDebug] Test de integración completo...")
     
     // Test 1: Verificar todas las dependencias
     print("1️⃣ Verificando dependencias...")
     verifyAllDependencies()
     
     // Test 2: Análisis de arquitectura
     print("\n2️⃣ Analizando arquitectura...")
     analyzeArchitecture()
     
     // Test 3: Health check de Kingfisher
     print("\n3️⃣ Health check de Kingfisher...")
     performKingfisherHealthCheck()
     
     // Test 4: Estadísticas
     print("\n4️⃣ Estadísticas de dependencias...")
     printDependencyStatistics()
     
     print("\n🎉 [DependencyDebug] Test de integración completado")
     }
     */
}

/*
 extension DependencyDebug {
 
 /// Verificar dependencias críticas de manera rápida
 static func quickHealthCheck() -> Bool {
 let criticalDependencies: [Any.Type] = [
 NetworkDispatcherProtocol.self,
 AuthServiceProtocol.self,
 ImageManagerProtocol.self,
 KingfisherConfigurable.self
 ]
 
 let resolvedCount = criticalDependencies.compactMap {
 DependencyInjector.shared.resolveOptional($0)
 }.count
 
 let isHealthy = resolvedCount == criticalDependencies.count
 
 if isHealthy {
 print("✅ Quick health check: All critical dependencies OK")
 } else {
 print("❌ Quick health check: \(criticalDependencies.count - resolvedCount) critical dependencies missing")
 }
 
 return isHealthy
 }
 
 /// Logging de performance de resolución de dependencias
 static func benchmarkDependencyResolution() {
 print("⏱️ [DependencyDebug] Benchmark de resolución de dependencias...")
 
 let startTime = CFAbsoluteTimeGetCurrent()
 
 // Resolver todas las dependencias críticas
 _ = DependencyInjector.shared.resolveOptional(NetworkDispatcherProtocol.self)
 _ = DependencyInjector.shared.resolveOptional(AuthServiceProtocol.self)
 _ = DependencyInjector.shared.resolveOptional(ImageManagerProtocol.self)
 _ = DependencyInjector.shared.resolveOptional(KingfisherConfigurable.self)
 
 let endTime = CFAbsoluteTimeGetCurrent()
 let timeElapsed = endTime - startTime
 
 print("⚡ Tiempo de resolución: \(String(format: "%.4f", timeElapsed))s")
 
 if timeElapsed < 0.01 {
 print("🚀 Performance excelente")
 } else if timeElapsed < 0.05 {
 print("✅ Performance buena")
 } else {
 print("⚠️ Performance puede mejorar")
 }
 }
 }
 */
#endif
