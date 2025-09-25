//
//  AppCoordinator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI
import Combine

// MARK: - App Level Coordinator
enum AppScreen: Hashable, CaseIterable {
    case splash
    case authentication
    case main
    
    var description: String {
        switch self {
        case .splash: return "Splash"
        case .authentication: return "Authentication"
        case .main: return "Main"
        }
    }
}

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
    
    private let authStateManager: AuthStateManager
    private var cancellables = Set<AnyCancellable>()
    private var isTransitioning = false
    private var lastAuthState: AuthState?
    
    // Timer para timeout de splash
    private var splashTimer: Timer?
    
    init(authStateManager: AuthStateManager) {
        self.authStateManager = authStateManager
        setupBindings()
        setupSplashTimeout()
        Logger.info("🎯 AppCoordinator: Initialized with improved state management")
    }
    
    private func setupBindings() {
        authStateManager.$authState
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] authState in
                guard let self = self else { return }
                
                Logger.debug("🔄 AppCoordinator: AuthState changed to: \(authState)")
                
                // Evitar navegaciones duplicadas
                if let lastState = self.lastAuthState,
                   self.isSameAuthState(lastState, authState) {
                    Logger.debug("🔄 AppCoordinator: Skipping duplicate auth state")
                    return
                }
                
                self.lastAuthState = authState
                self.handleAuthStateChange(authState)
            }
            .store(in: &cancellables)
    }
    
    private func setupSplashTimeout() {
        // Timeout automático del splash después de 10 segundos
        splashTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.currentScreen == .splash {
                    Logger.warning("⏰ AppCoordinator: Splash timeout - forcing navigation to auth")
                    self.navigate(to: .authentication)
                }
            }
        }
    }
    
    private func handleAuthStateChange(_ authState: AuthState) {
        // Evitar navegaciones durante transiciones
        guard !isTransitioning else {
            Logger.debug("🔄 AppCoordinator: Skipping navigation - already transitioning")
            return
        }
        
        switch authState {
        case .loading:
            // Solo mantener splash si estamos en estado inicial
            if currentScreen == .splash {
                Logger.debug("🔄 AppCoordinator: Staying on splash during initial loading")
            } else {
                Logger.debug("🔄 AppCoordinator: Loading state - maintaining current screen: \(currentScreen.description)")
            }
            
        case .loggingOut:  // 🆕 Nuevo caso para logout
                    Logger.debug("🚪 AppCoordinator: Logout in progress - maintaining current screen: \(currentScreen.description)")
            
        case .authenticated(let user):
            Logger.info("✅ AppCoordinator: User authenticated: \(user.displayName)")
            invalidateSplashTimer()
            navigate(to: .main)
            
        case .unauthenticated:
            Logger.info("📱 AppCoordinator: User unauthenticated")
            invalidateSplashTimer()
            navigate(to: .authentication)
            
        case .error(let errorMessage):
            Logger.error("❌ AppCoordinator: Auth error: \(errorMessage)")
            invalidateSplashTimer()
            navigate(to: .authentication)
        }
    }
    
    private func isSameAuthState(_ state1: AuthState, _ state2: AuthState) -> Bool {
        switch (state1, state2) {
        case (.loading, .loading), (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let user1), .authenticated(let user2)):
            return user1.id == user2.id
        case (.error(let error1), .error(let error2)):
            return error1 == error2
        default:
            return false
        }
    }
    
    func navigate(to screen: AppScreen) {
        guard currentScreen != screen else {
            Logger.debug("🔄 AppCoordinator: Already on screen \(screen.description)")
            return
        }
        
        guard !isTransitioning else {
            Logger.debug("🔄 AppCoordinator: Navigation blocked - already transitioning")
            return
        }
        
        Logger.info("🧭 AppCoordinator: Navigating from \(currentScreen.description) to \(screen.description)")
        
        isTransitioning = true
        
        // Invalidar timer si salimos de splash
        if currentScreen == .splash {
            invalidateSplashTimer()
        }
        
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.4)) {
                currentScreen = screen
            }
            
            // Esperar a que termine la animación
            try? await Task.sleep(for: .milliseconds(500))
            isTransitioning = false
            
            Logger.debug("✅ AppCoordinator: Navigation to \(screen.description) completed")
        }
    }
    
    func resetToInitialState() {
        Logger.warning("🔄 AppCoordinator: Resetting to initial state")
        
        invalidateSplashTimer()
        isTransitioning = false
        lastAuthState = nil
        
        navigate(to: .splash)
        
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await authStateManager.checkInitialAuthState()
            setupSplashTimeout()
        }
    }
    
    private func invalidateSplashTimer() {
        splashTimer?.invalidate()
        splashTimer = nil
    }
}

// MARK: - Main Tab Enum
enum MainTab: Int, CaseIterable, Identifiable {
    case feed = 0
    case marketplace = 1
    case create = 2
    case notifications = 3
    case profile = 4
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .feed: return "Feed"
        case .marketplace: return "Marketplace"
        case .create: return "Create Post"
        case .notifications: return "Notifications"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .feed: return "house"
        case .marketplace: return "storefront"
        case .create: return "plus.circle"
        case .notifications: return "envelope"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .feed: return "house.fill"
        case .marketplace: return "storefront.fill"
        case .create: return "plus.circle.fill"
        case .notifications: return "envelope.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Coordinator Factory
class CoordinatorFactory {
    @MainActor
    static func makeAppCoordinator() -> AppCoordinator {
        let authStateManager = DependencyInjector.shared.resolve(AuthStateManager.self)
        return AppCoordinator(authStateManager: authStateManager)
    }
    
    @MainActor
    static func makeNavigationCoordinator() -> NavigationCoordinator {
        return NavigationCoordinator()
    }
}

// MARK: - Debug Extensions
#if DEBUG
extension AppCoordinator {
    
    func debugNavigate(to screen: AppScreen) {
        Logger.debug("🧪 AppCoordinator: Debug navigation to \(screen.description)")
        navigate(to: screen)
    }
    
    func debugPrintState() {
        print("""
        
        🎯 ===== AppCoordinator Debug State =====
        Current Screen: \(currentScreen.description)
        Is Transitioning: \(isTransitioning)
        Last Auth State: \(lastAuthState?.description ?? "nil")
        Current Auth State: \(authStateManager.authState.description)
        Splash Timer Active: \(splashTimer != nil)
        ========================================
        
        """)
    }
    
    func forceAuthCheck() {
        Logger.debug("🧪 AppCoordinator: Force auth check triggered")
        Task {
            await authStateManager.checkInitialAuthState()
        }
    }
}

extension AuthState {
    var description: String {
        switch self {
        case .loading:
            return "Loading"
        case .loggingOut:
                    return "LoggingOut"
        case .authenticated(let user):
            return "Authenticated(\(user.displayName))"
        case .unauthenticated:
            return "Unauthenticated"
        case .error(let message):
            return "Error(\(message))"
        }
    }
}
#endif
