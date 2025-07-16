//
//  DependencyInjector.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class DependencyInjector {
    static let shared = DependencyInjector()
    
    private let container: Container
    private let assembler: Assembler
    
    private init() {
        container = Container()
        
        // Register all assemblies
        assembler = Assembler(
            [
                // MARK: - Core
                NetworkAssembly(),
                StorageAssembly(),
                
                // MARK: - Feature Flags
                FeatureFlagAssembly(),
                
                // MARK: - Image Loading
                KingfisherAssembly(),
                
                // MARK: - Data
                ServiceAssembly(),
                RepositoryAssembly(),
                
                // MARK: - Features
                AuthAssembly(),
                
                // MARK: - Generic
                ViewModelAssembly()
            ],
            container: container
        )
        
        Logger.info("🎯 Networking architecture initialized successfully")
        Logger.info("🖼️ Image loading architecture initialized with Kingfisher")
        
#if DEBUG
        // Verify dependencies in debug mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            DependencyDebug.verifyAllDependencies()
            DependencyDebug.performKingfisherHealthCheck()
        }
#endif
    }
    
    /// Resolve a dependency of a specific type
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolvedType = container.resolve(T.self) else {
            Logger.error("Could not resolve type: \(String(describing: T.self))")
            fatalError("Could not resolve type \(String(describing: T.self))")
        }
        return resolvedType
    }
    
    /// Resolve a dependency with arguments
    func resolve<T, Arg1>(_ type: T.Type, arguments arg1: Arg1) -> T {
        guard let resolvedType = container.resolve(T.self, argument: arg1) else {
            Logger.error("Could not resolve type: \(String(describing: T.self)) with argument")
            fatalError("Could not resolve type \(String(describing: T.self)) with argument")
        }
        return resolvedType
    }
    
    /// Resolve a dependency with multiple arguments
    func resolve<T, Arg1, Arg2>(_ type: T.Type, arguments arg1: Arg1, _ arg2: Arg2) -> T {
        guard let resolvedType = container.resolve(T.self, arguments: arg1, arg2) else {
            Logger.error("Could not resolve type: \(String(describing: T.self)) with arguments")
            fatalError("Could not resolve type \(String(describing: T.self)) with arguments")
        }
        return resolvedType
    }
    
    /// Resolve a dependency with three arguments
    func resolve<T, Arg1, Arg2, Arg3>(_ type: T.Type, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) -> T {
        guard let resolvedType = container.resolve(T.self, arguments: arg1, arg2, arg3) else {
            Logger.error("Could not resolve type: \(String(describing: T.self)) with arguments")
            fatalError("Could not resolve type \(String(describing: T.self)) with arguments")
        }
        return resolvedType
    }
}

// MARK: - Factory Methods (MainActor-safe creation)
extension DependencyInjector {
    
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        return resolve(AuthViewModel.self)
    }
    
    @MainActor
    func getAuthStateManager() -> AuthStateManager {
        return resolve(AuthStateManager.self)
    }
    
    func getImageManager() -> ImageManagerProtocol {
        return resolve(ImageManagerProtocol.self)
    }
    
    func getImageCacheService() -> ImageCacheServiceProtocol {
        return resolve(ImageCacheServiceProtocol.self)
    }
    
    func getKingfisherConfig() -> KingfisherConfigurable {
        return resolve(KingfisherConfigurable.self)
    }
}

// MARK: - Environment Setup
extension DependencyInjector {
    
    /// Configure container for testing environment
    func configureForTesting() {
        // Remove all existing registrations
        container.removeAll()
        
        // Register mock services for testing
        Logger.info("Container configured for testing")
    }
    
    /// Configure container for preview environment
    func configureForPreviews() {
        Logger.info("Container configured for previews")
    }
}

// MARK: - Extensions for Optional Resolution
extension DependencyInjector {
    
    /// Resuelve una dependencia de forma segura, retornando nil si no se puede resolver
    func resolveOptional<T>(_ type: T.Type) -> T? {
        return container.resolve(T.self)
    }
    
    /// Resuelve una dependencia de forma segura con argumentos
    func resolveOptional<T, Arg1>(_ type: T.Type, argument arg1: Arg1) -> T? {
        return container.resolve(T.self, argument: arg1)
    }
    
    /// Verifica si una dependencia puede ser resuelta
    func canResolve<T>(_ type: T.Type) -> Bool {
        return resolveOptional(type) != nil
    }
    
    /// Resuelve una dependencia usando throws en lugar de fatalError
    func resolveThrows<T>(_ type: T.Type) throws -> T {
        guard let resolvedType = container.resolve(T.self) else {
            throw DependencyInjectionError.cannotResolve(String(describing: T.self))
        }
        return resolvedType
    }
}

extension DependencyInjector {
    
    /// Quick access to image manager for SwiftUI Environment
    var imageManager: ImageManagerProtocol {
        return resolve(ImageManagerProtocol.self)
    }
    
    /// Quick access to cache service
    var imageCacheService: ImageCacheServiceProtocol {
        return resolve(ImageCacheServiceProtocol.self)
    }
    
    /// Quick access to download service
    var imageDownloadService: ImageDownloaderServiceProtocol {
        return resolve(ImageDownloaderServiceProtocol.self)
    }
    
    /// Quick access to processing service
    var imageProcessingService: ImageProcessingServiceProtocol {
        return resolve(ImageProcessingServiceProtocol.self)
    }
}

/*
 extension DependencyInjector {
 
 /// Check if all critical dependencies are available
 var isHealthy: Bool {
 let criticalTypes: [Any.Type] = [
 NetworkDispatcherProtocol.self,
 AuthServiceProtocol.self,
 ImageManagerProtocol.self,
 KingfisherConfigurable.self
 ]
 
 return criticalTypes.allSatisfy { canResolve($0) }
 }
 
 /// Get container statistics
 var containerStats: ContainerStats {
 return ContainerStats(
 totalRegistrations: getTotalRegistrations(),
 criticalDependenciesCount: getCriticalDependenciesCount(),
 kingfisherDependenciesCount: getKingfisherDependenciesCount(),
 isHealthy: isHealthy
 )
 }
 
 private func getTotalRegistrations() -> Int {
 // This is an approximation since Swinject doesn't expose direct count
 let testTypes: [Any.Type] = [
 NetworkDispatcherProtocol.self,
 AuthServiceProtocol.self,
 ImageManagerProtocol.self,
 KingfisherConfigurable.self,
 TokenManager.self,
 SecureStorageProtocol.self,
 UserDefaultsManagerProtocol.self,
 ImageCacheServiceProtocol.self,
 ImageDownloaderServiceProtocol.self,
 ImageProcessingServiceProtocol.self
 ]
 
 return testTypes.compactMap { resolveOptional($0) }.count
 }
 
 private func getCriticalDependenciesCount() -> Int {
 let criticalTypes: [Any.Type] = [
 NetworkDispatcherProtocol.self,
 AuthServiceProtocol.self,
 ImageManagerProtocol.self,
 KingfisherConfigurable.self
 ]
 
 return criticalTypes.compactMap { resolveOptional($0) }.count
 }
 
 private func getKingfisherDependenciesCount() -> Int {
 let kingfisherTypes: [Any.Type] = [
 KingfisherConfigurable.self,
 ImageManagerProtocol.self,
 ImageCacheServiceProtocol.self,
 ImageDownloaderServiceProtocol.self,
 ImageProcessingServiceProtocol.self
 ]
 
 return kingfisherTypes.compactMap { resolveOptional($0) }.count
 }
 }
 */

// MARK: - Error Types
enum DependencyInjectionError: Error, LocalizedError {
    case cannotResolve(String)
    
    var errorDescription: String? {
        switch self {
        case .cannotResolve(let typeName):
            return "No se pudo resolver la dependencia: \(typeName)"
        }
    }
}

