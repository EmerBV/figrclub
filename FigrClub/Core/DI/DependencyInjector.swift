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
        
#if DEBUG
        // Verify dependencies in debug mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            DependencyDebug.verifyAllDependencies()
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

