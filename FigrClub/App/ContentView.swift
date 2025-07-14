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
    
    init() {
        // Crear el coordinator en el hilo principal
        self._appCoordinator = StateObject(wrappedValue: CoordinatorFactory.makeAppCoordinator())
    }
    
    var body: some View {
        Group {
            switch appCoordinator.currentScreen {
            case .splash:
                SplashView()
                    .onAppear {
                        setupInitializationTimeout()
                    }
                
            case .authentication:
                AuthenticationFlowView()
                    .environmentObject(authStateManager)
                
            case .main:
                MainTabView()
                    .onAppear {
                        // Reset timeout cuando llegamos a main
                        initializationTimeout = false
                    }
            }
        }
        .environmentObject(appCoordinator)
        .animation(.easeInOut(duration: AppConfig.UI.animationDuration), value: appCoordinator.currentScreen)
        .task {
            await performInitialAuthCheck()
        }
        // Overlay para manejar estado de timeout
        .overlay(alignment: .topTrailing) {
            if initializationTimeout {
                timeoutOverlay
            }
        }
        // Debug overlay en modo debug
#if DEBUG
        .overlay(alignment: .bottomTrailing) {
            if showDebugInfo {
                debugOverlay
            }
        }
        .onLongPressGesture(minimumDuration: 3.0) {
            showDebugInfo.toggle()
        }
#endif
    }
    
    // MARK: - Private Views
    
    private var timeoutOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            Text("Inicialización tardando más de lo esperado")
                .font(.callout)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }
    
#if DEBUG
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🐛 Debug Info")
                .font(.caption.bold())
            
            Text("Screen: \(appCoordinator.currentScreen)")
            Text("Auth: \(authStateManager.authState)")
            Text("User: \(authStateManager.currentUser?.username ?? "nil")")
            
            Button("Force Auth Check") {
                Task {
                    await authStateManager.checkInitialAuthState()
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
            
            Button("Reset Coordinator") {
                appCoordinator.resetToInitialState()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .font(.caption)
        .padding(8)
        .background(.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
        .padding()
    }
#endif
    
    // MARK: - Private Methods
    
    private func performInitialAuthCheck() async {
        Logger.info("🚀 ContentView: Starting initial auth check")
        
        // Pequeño delay para permitir que la UI se configure
        try? await Task.sleep(for: .milliseconds(100))
        
        await authStateManager.checkInitialAuthState()
        
        Logger.info("✅ ContentView: Initial auth check completed")
    }
    
    private func setupInitializationTimeout() {
        // Timeout de 10 segundos para la inicialización
        Task {
            try? await Task.sleep(for: .seconds(10))
            
            await MainActor.run {
                // Solo mostrar timeout si aún estamos en splash
                if appCoordinator.currentScreen == .splash {
                    initializationTimeout = true
                    Logger.warning("⚠️ ContentView: Initialization timeout reached")
                }
            }
        }
    }
    
    private func retryInitialization() {
        initializationTimeout = false
        Logger.info("🔄 ContentView: Retrying initialization")
        
        Task {
            appCoordinator.resetToInitialState()
            await performInitialAuthCheck()
        }
    }
    
    private func forceNavigationToAuth() {
        initializationTimeout = false
        Logger.warning("🔧 ContentView: Force navigating to authentication")
        appCoordinator.navigate(to: .authentication)
    }
}

// MARK: - Supporting Views
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                
                Text("Cargando FigrClub...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Error View mejorada para casos de fallo
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onSkip: (() -> Void)?
    
    init(message: String, onRetry: @escaping () -> Void, onSkip: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
        self.onSkip = onSkip
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Algo salió mal")
                        .font(.title2.weight(.semibold))
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Button("Reintentar") {
                        onRetry()
                    }
                    .buttonStyle(FigrButtonStyle())
                    
                    if let onSkip = onSkip {
                        Button("Continuar sin autenticación") {
                            onSkip()
                        }
                        .font(.callout)
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DependencyInjector.shared.resolve(AuthStateManager.self))
    }
}
#endif
