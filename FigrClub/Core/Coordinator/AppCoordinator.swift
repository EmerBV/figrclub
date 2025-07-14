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
    
    init(authStateManager: AuthStateManager) {
        self.authStateManager = authStateManager
        setupBindings()
        Logger.info("🎯 AppCoordinator: Initialized with simplified architecture")
    }
    
    private func setupBindings() {
        authStateManager.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authState in
                guard let self = self else { return }
                
                Logger.debug("🔄 AppCoordinator: AuthState changed to: \(authState)")
                
                // Evitar navegaciones duplicadas durante transiciones
                guard !self.isTransitioning else {
                    Logger.debug("🔄 AppCoordinator: Skipping navigation - already transitioning")
                    return
                }
                
                switch authState {
                case .loading:
                    // Solo mantener splash en loading inicial
                    if self.currentScreen == .splash {
                        Logger.debug("🔄 AppCoordinator: Staying on splash during loading")
                    }
                    
                case .authenticated(let user):
                    Logger.info("✅ AppCoordinator: User authenticated: \(user.displayName)")
                    self.navigate(to: .main)
                    
                case .unauthenticated:
                    Logger.info("📱 AppCoordinator: User unauthenticated")
                    self.navigate(to: .authentication)
                    
                case .error(let errorMessage):
                    Logger.error("❌ AppCoordinator: Auth error: \(errorMessage)")
                    self.navigate(to: .authentication)
                }
            }
            .store(in: &cancellables)
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
        
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentScreen = screen
            }
            
            try? await Task.sleep(for: .milliseconds(400))
            isTransitioning = false
        }
    }
    
    func resetToInitialState() {
        Logger.warning("🔄 AppCoordinator: Resetting to initial state")
        isTransitioning = false
        navigate(to: .splash)
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            await authStateManager.checkInitialAuthState()
        }
    }
}

// MARK: - Main Tab Enum (Simple)
enum MainTab: Int, CaseIterable {
    case feed = 0
    case marketplace = 1
    case create = 2
    case notifications = 3
    case profile = 4
    
    var title: String {
        switch self {
        case .feed: return "Feed"
        case .marketplace: return "Marketplace"
        case .create: return "Crear"
        case .notifications: return "Notificaciones"
        case .profile: return "Perfil"
        }
    }
    
    var icon: String {
        switch self {
        case .feed: return "house"
        case .marketplace: return "cart"
        case .create: return "plus.circle"
        case .notifications: return "bell"
        case .profile: return "person"
        }
    }
}

// MARK: - Navigation Coordinator (Secundario)
@MainActor
class NavigationCoordinator: ObservableObject {
    // Estados de navegación modal/sheet
    @Published var showingPostDetail = false
    @Published var showingUserProfile = false
    @Published var showingSettings = false
    @Published var showingEditProfile = false
    
    // IDs para navegación
    @Published var selectedPostId: String?
    @Published var selectedUserId: String?
    
    // Métodos de navegación
    func showPostDetail(_ postId: String) {
        selectedPostId = postId
        showingPostDetail = true
    }
    
    func showUserProfile(_ userId: String) {
        selectedUserId = userId
        showingUserProfile = true
    }
    
    func showSettings() {
        showingSettings = true
    }
    
    func showEditProfile() {
        showingEditProfile = true
    }
    
    func dismissAll() {
        showingPostDetail = false
        showingUserProfile = false
        showingSettings = false
        showingEditProfile = false
        selectedPostId = nil
        selectedUserId = nil
    }
}

// MARK: - Coordinator Factory (Simplificado)
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
