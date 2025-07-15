//
//  ContentView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appCoordinator: AppCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    // Estado para manejar timeouts y errores de inicialización
    @State private var initializationTimeout = false
    @State private var showDebugInfo = false
    @State private var hasInitialized = false
    @State private var debugTapCount = 0
    
    init() {
        // Crear el coordinator en el hilo principal
        self._appCoordinator = StateObject(wrappedValue: CoordinatorFactory.makeAppCoordinator())
    }
    
    var body: some View {
        ZStack {
            // Contenido principal
            Group {
                switch appCoordinator.currentScreen {
                case .splash:
                    SplashView()
                        .onAppear {
                            setupInitializationTimeout()
                        }
                    
                case .authentication:
                    AuthenticationFlowView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                    
                case .main:
                    // ✅ FIX: Renderizar MainTabView solo cuando tenemos un usuario autenticado
                    if case .authenticated(let user) = authStateManager.authState {
                        MainTabView(user: user)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                            .onAppear {
                                // Reset timeout cuando llegamos a main
                                initializationTimeout = false
                            }
                    } else {
                        // ✅ Mostrar loading mientras se obtiene el usuario
                        EBVLoadingView.appLaunch
                            .onAppear {
                                Logger.debug("🔄 ContentView: Waiting for authenticated user in main screen")
                                // Si llevamos mucho tiempo sin usuario, volver a auth
                                Task {
                                    try? await Task.sleep(for: .seconds(5))
                                    if case .main = appCoordinator.currentScreen,
                                       !authStateManager.isAuthenticated {
                                        Logger.warning("⚠️ ContentView: No authenticated user found, returning to auth")
                                        await MainActor.run {
                                            appCoordinator.navigate(to: .authentication)
                                        }
                                    }
                                }
                            }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: appCoordinator.currentScreen)
            
            // Overlay para timeout
            if initializationTimeout {
                timeoutOverlay
            }
            
            // Debug overlay
#if DEBUG
            if showDebugInfo {
                debugOverlay
            }
#endif
        }
        .environmentObject(appCoordinator)
        .task {
            if !hasInitialized {
                await performInitialAuthCheck()
                hasInitialized = true
            }
        }
        // Debug tap gesture
#if DEBUG
        .onTapGesture(count: 5) {
            handleDebugTap()
        }
#endif
        // ✅ Observar cambios de estado para navegación automática
        .onReceive(authStateManager.$authState) { authState in
            Logger.debug("🔄 ContentView: AuthState changed to: \(authState)")
            handleAuthStateChange(authState)
        }
        .onReceive(appCoordinator.$currentScreen) { screen in
            Logger.debug("🧭 ContentView: Screen changed to: \(screen)")
        }
    }
    
    // MARK: - Private Views
    
    private var timeoutOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Inicialización lenta")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("La app está tardando más de lo esperado en cargar")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 16) {
                    Button("Reintentar") {
                        retryInitialization()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Continuar") {
                        forceNavigationToAuth()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .background(.regularMaterial)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }
    
#if DEBUG
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🐛 FigrClub Debug")
                .font(.caption.bold())
                .foregroundColor(.white)
            
            Group {
                Text("Screen: \(appCoordinator.currentScreen)")
                Text("Auth: \(authStateManager.authState.debugDescription)")
                Text("User: \(authStateManager.currentUser?.username ?? "nil")")
                Text("Initialized: \(hasInitialized)")
                Text("Is Authenticated: \(authStateManager.isAuthenticated)")
                
                if let user = authStateManager.currentUser {
                    Text("User ID: \(user.id)")
                }
            }
            .font(.caption2)
            .foregroundColor(.white)
            
            VStack(spacing: 4) {
                Button("Force Auth Check") {
                    Task {
                        await authStateManager.checkInitialAuthState()
                    }
                }
                
                Button("Reset App") {
                    appCoordinator.resetToInitialState()
                    hasInitialized = false
                }
                
                Button("Go to Auth") {
                    appCoordinator.debugNavigate(to: .authentication)
                }
                
                Button("Go to Main") {
                    appCoordinator.debugNavigate(to: .main)
                }
                
                Button("Print States") {
                    appCoordinator.debugPrintState()
                    authStateManager.debugCurrentState()
                }
                
                Button("Close Debug") {
                    showDebugInfo = false
                }
            }
            .font(.caption2)
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(.black.opacity(0.8))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .position(x: UIScreen.main.bounds.width / 2, y: 150)
    }
#endif
    
    // MARK: - Private Methods
    
    private func handleAuthStateChange(_ authState: AuthState) {
        Task { @MainActor in
            switch authState {
            case .authenticated(let user):
                Logger.info("✅ ContentView: User authenticated: \(user.displayName)")
                // Solo navegar a main si no estamos ya ahí
                if appCoordinator.currentScreen != .main {
                    appCoordinator.navigate(to: .main)
                }
                
            case .unauthenticated:
                Logger.info("🚪 ContentView: User unauthenticated")
                // Solo navegar a auth si no estamos ya ahí o en splash
                if appCoordinator.currentScreen == .main {
                    appCoordinator.navigate(to: .authentication)
                }
                
            case .error(let errorMessage):
                Logger.error("❌ ContentView: Auth error: \(errorMessage)")
                // En caso de error, ir a authentication para que el usuario pueda reintentar
                if appCoordinator.currentScreen == .main {
                    appCoordinator.navigate(to: .authentication)
                }
                
            case .loading:
                Logger.debug("🔄 ContentView: Auth loading...")
                // No hacer nada, mantener pantalla actual
            }
        }
    }
    
    private func performInitialAuthCheck() async {
        Logger.info("🚀 ContentView: Starting initial auth check")
        
        // Asegurar que comenzamos en splash
        await MainActor.run {
            if appCoordinator.currentScreen != .splash {
                appCoordinator.navigate(to: .splash)
            }
        }
        
        // Pequeño delay para permitir que la UI se configure
        try? await Task.sleep(for: .milliseconds(500))
        
        await authStateManager.checkInitialAuthState()
        
        Logger.info("✅ ContentView: Initial auth check completed")
    }
    
    private func setupInitializationTimeout() {
        // Timeout de 15 segundos para la inicialización
        Task {
            try? await Task.sleep(for: .seconds(15))
            
            await MainActor.run {
                // Solo mostrar timeout si aún estamos en splash
                if appCoordinator.currentScreen == .splash && hasInitialized {
                    initializationTimeout = true
                    Logger.warning("⚠️ ContentView: Initialization timeout reached")
                }
            }
        }
    }
    
    private func retryInitialization() {
        initializationTimeout = false
        hasInitialized = false
        Logger.info("🔄 ContentView: Retrying initialization")
        
        Task {
            appCoordinator.resetToInitialState()
            await performInitialAuthCheck()
            hasInitialized = true
        }
    }
    
    private func forceNavigationToAuth() {
        initializationTimeout = false
        Logger.warning("🔧 ContentView: Force navigating to authentication")
        appCoordinator.navigate(to: .authentication)
    }
    
#if DEBUG
    private func handleDebugTap() {
        debugTapCount += 1
        
        if debugTapCount >= 5 {
            showDebugInfo.toggle()
            debugTapCount = 0
            Logger.debug("🧪 ContentView: Debug mode toggled: \(showDebugInfo)")
        }
        
        // Reset counter después de 2 segundos
        Task {
            try? await Task.sleep(for: .seconds(2))
            debugTapCount = 0
        }
    }
#endif
}

extension ContentView {
    
    /// Add Feature Flag Manager to environment
    var bodyWithFeatureFlags: some View {
        body
            .environmentObject(DependencyInjector.shared.getFeatureFlagManager())
    }
}

// MARK: - Extensions para Debug
#if DEBUG
extension AuthState {
    var debugDescription: String {
        switch self {
        case .loading:
            return "Loading"
        case .authenticated(let user):
            return "Auth(\(user.displayName))"
        case .unauthenticated:
            return "Unauth"
        case .error(let message):
            return "Error(\(message.prefix(20)))"
        }
    }
}
#endif

// MARK: - Preview
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DependencyInjector.shared.resolve(AuthStateManager.self))
    }
}
#endif
