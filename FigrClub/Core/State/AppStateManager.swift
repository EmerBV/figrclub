//
//  AppStateManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - App State
enum AppState: Equatable {
    case initializing
    case splash
    case authentication
    case authenticated(User)
    case maintenance
    case error(AppError)
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.splash, .splash),
             (.authentication, .authentication),
             (.maintenance, .maintenance):
            return true
        case (.authenticated(let user1), .authenticated(let user2)):
            return user1.id == user2.id
        case (.error(let error1), .error(let error2)):
            return error1.localizedDescription == error2.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - App Error
enum AppError: Error, LocalizedError {
    case initializationFailed
    case authenticationFailed(Error)
    case networkUnavailable
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Error al inicializar la aplicación"
        case .authenticationFailed(let error):
            return "Error de autenticación: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Red no disponible"
        case .unknown(let error):
            return "Error desconocido: \(error.localizedDescription)"
        }
    }
}

// MARK: - App State Manager
@MainActor
final class AppStateManager: ObservableObject {
    // MARK: - Published State
    @Published private(set) var appState: AppState = .initializing
    @Published private(set) var isLoading = false
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    
    // MARK: - Dependencies
    private let authStateManager: AuthStateManager
    private var cancellables = Set<AnyCancellable>()
    private var initializationTimer: Timer?
    
    // MARK: - Initialization
    init(authStateManager: AuthStateManager) {
        self.authStateManager = authStateManager
        setupBindings()
        startInitialization()
        Logger.info("🎯 AppStateManager: Initialized")
    }
    
    // MARK: - Public Methods
    
    func startInitialization() {
        Logger.info("🚀 AppStateManager: Starting initialization")
        appState = .initializing
        isLoading = true
        
        // Setup timeout for initialization
        initializationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.handleInitializationTimeout()
            }
        }
        
        // Trigger auth state check
        Task {
            await authStateManager.checkInitialAuthState()
        }
    }
    
    func navigateToAuthentication() {
        Logger.info("🔄 AppStateManager: Navigating to authentication")
        appState = .authentication
        isLoading = false
    }
    
    func handleMaintenanceMode() {
        Logger.warning("🚧 AppStateManager: Entering maintenance mode")
        appState = .maintenance
        isLoading = false
    }
    
    func handleCriticalError(_ error: Error) {
        Logger.error("💥 AppStateManager: Critical error: \(error)")
        let appError = AppError.unknown(error)
        appState = .error(appError)
        isLoading = false
    }
    
    func retry() {
        Logger.info("🔄 AppStateManager: Retrying initialization")
        startInitialization()
    }
    
    // MARK: - State Queries
    
    var currentScreen: AppScreen {
        switch appState {
        case .initializing, .splash:
            return .splash
        case .authentication, .error:
            return .authentication
        case .authenticated, .maintenance:
            return .main
        }
    }
    
    var shouldShowSplash: Bool {
        switch appState {
        case .initializing, .splash:
            return true
        default:
            return false
        }
    }
    
    var shouldShowAuthentication: Bool {
        switch appState {
        case .authentication, .error:
            return true
        default:
            return false
        }
    }
    
    var shouldShowMain: Bool {
        switch appState {
        case .authenticated:
            return true
        default:
            return false
        }
    }
}

// MARK: - Private Methods
private extension AppStateManager {
    
    func setupBindings() {
        // Bind to auth state changes
        authStateManager.$authState
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] authState in
                self?.handleAuthStateChange(authState)
            }
            .store(in: &cancellables)
        
        // Bind current user
        authStateManager.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
        
        // Bind authentication status
        authStateManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        Logger.debug("✅ AppStateManager: Bindings setup completed")
    }
    
    func handleAuthStateChange(_ authState: AuthState) {
        Logger.debug("🔄 AppStateManager: Auth state changed to: \(authState)")
        
        // Cancel initialization timer when auth state changes
        initializationTimer?.invalidate()
        initializationTimer = nil
        
        switch authState {
        case .loading:
            // Don't change app state during auth loading unless we're initializing
            if case .initializing = appState {
                appState = .splash
            }
            isLoading = true
            
        case .loggingOut:
            Logger.info("🔄 AppStateManager: User logging out")
            isLoading = true
            appState = .splash
            
        case .authenticated(let user):
            Logger.info("✅ AppStateManager: User authenticated: \(user.displayName)")
            appState = .authenticated(user)
            isLoading = false
            
        case .unauthenticated:
            Logger.info("🔐 AppStateManager: User not authenticated")
            appState = .authentication
            isLoading = false
            
        case .error(let errorMessage):
            Logger.error("❌ AppStateManager: Auth error: \(errorMessage)")
            let authError = AppError.authenticationFailed(
                NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            )
            appState = .error(authError)
            isLoading = false
        }
    }
    
    func handleInitializationTimeout() async {
        Logger.warning("⏰ AppStateManager: Initialization timeout reached")
        
        // If still initializing after timeout, move to authentication
        if case .initializing = appState {
            appState = .authentication
            isLoading = false
        }
    }
}

// MARK: - Debug Extensions
#if DEBUG
extension AppStateManager {
    
    func debugState() -> String {
        return """
        AppStateManager Debug:
        - App State: \(appState)
        - Is Loading: \(isLoading)
        - Is Authenticated: \(isAuthenticated)
        - Current User: \(currentUser?.displayName ?? "nil")
        - Current Screen: \(currentScreen.description)
        """
    }
    
    func forceState(_ state: AppState) {
        Logger.debug("🧪 AppStateManager: Force setting state to: \(state)")
        appState = state
    }
}

extension AppState {
    var debugDescription: String {
        switch self {
        case .initializing:
            return "Initializing"
        case .splash:
            return "Splash"
        case .authentication:
            return "Authentication"
        case .authenticated(let user):
            return "Authenticated(\(user.displayName))"
        case .maintenance:
            return "Maintenance"
        case .error(let error):
            return "Error(\(error.localizedDescription))"
        }
    }
}
#endif 