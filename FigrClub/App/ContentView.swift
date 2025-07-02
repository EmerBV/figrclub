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
    @EnvironmentObject private var remoteConfigManager: RemoteConfigManager
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                SplashView()
                
            case .authenticated:
                MainTabView()
                
            case .unauthenticated:
                AuthenticationFlowView()
            }
        }
        .animation(.easeInOut(duration: AppConfig.UI.animationDuration), value: authManager.authState)
        .task {
            await authManager.checkAuthenticationStatus()
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

