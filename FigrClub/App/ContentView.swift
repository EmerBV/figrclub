//
//  ContentView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    var body: some View {
        Group {
            switch authStateManager.authState {
            case .loading:
                SplashView()
                
            case .authenticated(let user):
                MainTabView(user: user)
                    .environmentObject(authStateManager)
                
            case .unauthenticated:
                AuthenticationFlowView()
                    .environmentObject(authStateManager)
                
            case .error(let message):
                ErrorView(message: message) {
                    Task {
                        await authStateManager.checkInitialAuthState()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: AppConfig.UI.animationDuration), value: authStateManager.authState)
        .task {
            await authStateManager.checkInitialAuthState()
        }
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

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
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
                
                Button("Reintentar") {
                    onRetry()
                }
                .buttonStyle(FigrButtonStyle())
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


