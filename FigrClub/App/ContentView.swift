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
    @EnvironmentObject private var themeManager: ThemeManager
    
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
            // Background temático para toda la app
            themeManager.currentBackgroundColor
                .ignoresSafeArea()
            
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
                        loadingViewForCurrentAuthState
                            .onAppear {
                                Logger.debug("🔄 ContentView: Waiting for authenticated user in main screen")
                                Task {
                                    try? await Task.sleep(for: .seconds(5))
                                    if case .authenticated = authStateManager.authState {
                                        // Usuario autenticado, no hacer nada
                                    } else {
                                        Logger.warning("⚠️ ContentView: No authenticated user after timeout, navigating to auth")
                                        appCoordinator.navigate(to: .authentication)
                                    }
                                }
                            }
                    }
                }
            }
            
            // Overlay para debugging en desarrollo
#if DEBUG
            debugOverlay
#endif
            
            // Error timeout overlay
            if initializationTimeout {
                timeoutErrorOverlay
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appCoordinator.currentScreen)
        .environmentObject(appCoordinator)
        .onAppear {
            Logger.debug("✅ ContentView: Appeared with screen: \(appCoordinator.currentScreen.description)")
            setupAppCoordinator()
        }
        .onChange(of: authStateManager.authState) { oldState, newState in
            handleAuthStateChange(from: oldState, to: newState)
        }
        .onChange(of: appCoordinator.currentScreen) { oldScreen, newScreen in
            Logger.debug("📱 ContentView: Screen changed from \(oldScreen.description) to \(newScreen.description)")
        }
    }
    
    // MARK: - Loading View for Current Auth State
    
    @ViewBuilder
    private var loadingViewForCurrentAuthState: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Logo o branding
            /*
            Image("logo")
                .frame(width: 60, height: 60)
                .scaleEffect(1.2)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: UUID()
                )
             */
    
            Text(getLoadingMessage())
                .themedFont(.bodyMedium)
                .foregroundColor(themeManager.currentSecondaryTextColor)
                .multilineTextAlignment(.center)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                .scaleEffect(1.2)
        }
        .padding(.horizontal, AppTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentBackgroundColor)
    }
    
    private func getLoadingMessage() -> String {
        switch authStateManager.authState {
        case .loading:
            return "Verificando tu sesión..."
        case .unauthenticated:
            return "Configurando autenticación..."
        case .authenticated:
            return "Cargando tu perfil..."
        case .loggingOut:
            return "Cerrando sesión..."
        case .error:
            return "Reintentando conexión..."
        }
    }
    
    // MARK: - Debug Overlay
    
#if DEBUG
    @ViewBuilder
    private var debugOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                if showDebugInfo {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🏗️ Debug Info")
                            .themedFont(.bodyMedium)
                            .bold()
                        Text("Screen: \(appCoordinator.currentScreen.description)")
                            .themedFont(.bodySmall)
                        Text("Auth: \(authStateManager.authState.description)")
                            .themedFont(.bodySmall)
                        Text("Theme: \(themeManager.themeMode.displayName)")
                            .themedFont(.bodySmall)
                        Text("Color: \(themeManager.colorScheme == .dark ? "Dark" : "Light")")
                            .themedFont(.bodySmall)
                        
                        Button("Toggle Theme") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.toggleColorScheme()
                            }
                        }
                        .buttonStyle(.primary)
                        .scaleEffect(0.8)
                    }
                    .padding(8)
                    .background(
                        themeManager.currentCardColor.opacity(0.95)
                            .cornerRadius(8)
                    )
                    .shadow(radius: 4)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(.trailing, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.medium)
        }
        .onTapGesture(count: 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                debugTapCount += 1
                if debugTapCount >= 3 {
                    showDebugInfo.toggle()
                    debugTapCount = 0
                }
            }
        }
    }
#endif
    
    // MARK: - Timeout Error Overlay
    
    @ViewBuilder
    private var timeoutErrorOverlay: some View {
        ZStack {
            themeManager.currentBackgroundColor.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.large) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.orange)
                
                VStack(spacing: AppTheme.Spacing.medium) {
                    Text("Tiempo de espera agotado")
                        .themedFont(.headlineMedium)
                        .foregroundColor(themeManager.currentTextColor)
                    
                    Text("La aplicación está tardando más de lo esperado en inicializar. Puedes intentar nuevamente.")
                        .themedFont(.bodyMedium)
                        .foregroundColor(themeManager.currentSecondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: AppTheme.Spacing.medium) {
                    Button("Reintentar") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            initializationTimeout = false
                            appCoordinator.resetToInitialState()
                        }
                    }
                    .buttonStyle(.primary)
                    
                    Button("Continuar") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            initializationTimeout = false
                        }
                    }
                    .buttonStyle(.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xLarge)
            .padding(.vertical, AppTheme.Spacing.large)
            .background(
                themeManager.currentCardColor
                    .cornerRadius(16)
            )
            .shadow(radius: 10)
            .padding(.horizontal, AppTheme.Spacing.xLarge)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    // MARK: - Private Methods
    
    private func setupAppCoordinator() {
        // El AppCoordinator se inicializa automáticamente en su init
        // No necesitamos llamar métodos adicionales aquí
    }
    
    private func setupInitializationTimeout() {
        Task {
            try? await Task.sleep(for: .seconds(10)) // Timeout de 10 segundos
            if appCoordinator.currentScreen == .splash {
                await MainActor.run {
                    Logger.warning("⚠️ ContentView: Initialization timeout reached")
                    initializationTimeout = true
                }
            }
        }
    }
    
    private func handleAuthStateChange(from oldState: AuthState, to newState: AuthState) {
        Logger.debug("🔄 ContentView: Auth state changed from \(oldState.description) to \(newState.description)")
        
        // La navegación automática la maneja el AppCoordinator
        // Aquí solo manejamos efectos secundarios si es necesario
        
        switch newState {
        case .authenticated(let user):
            Logger.debug("✅ ContentView: User authenticated: \(user.displayName)")
            
        case .unauthenticated:
            Logger.debug("🚪 ContentView: User unauthenticated")
            
        case .error(let message):
            Logger.error("❌ ContentView: Auth error: \(message)")
            
        case .loading, .loggingOut:
            Logger.debug("🔄 ContentView: Auth loading state")
        }
    }
}

// MARK: - AuthState Description Extension
/*
 extension AuthState {
 var description: String {
 switch self {
 case .loading:
 return "Loading"
 case .loggingOut:
 return "LoggingOut"
 case .unauthenticated:
 return "Unauthenticated"
 case .authenticated(let user):
 return "Authenticated(\(user.displayName))"
 case .error(let message):
 return "Error(\(message))"
 }
 }
 }
 */
