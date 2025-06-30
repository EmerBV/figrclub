//
//  ContentView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var isInitializing = true
    
    var body: some View {
        Group {
            if isInitializing {
                LoadingView(message: "Iniciando FigrClub...")
            } else {
                switch authManager.authState {
                case .authenticated:
                    MainTabView()
                        .transition(.opacity)
                    
                case .unauthenticated:
                    LoginView()
                        .transition(.opacity)
                    
                case .loading:
                    LoadingView(message: "Autenticando...")
                    
                case .error(let error):
                    ErrorView(
                        message: error.localizedDescription,
                        buttonTitle: "Reintentar"
                    ) {
                        Task {
                            _ = await authManager.getCurrentUser()
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.authState)
        .task {
            // Simulate initialization time
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            withAnimation {
                isInitializing = false
            }
        }
    }
}

// MARK: - Auth State Pattern Matching Extension
extension AuthState: Equatable {
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated),
            (.loading, .loading):
            return true
        case let (.authenticated(user1), .authenticated(user2)):
            return user1.id == user2.id
        case let (.error(error1), .error(error2)):
            return error1.localizedDescription == error2.localizedDescription
        default:
            return false
        }
    }
}

