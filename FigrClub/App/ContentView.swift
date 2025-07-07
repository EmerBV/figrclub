//
//  ContentView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                SplashView()
                
            case .authenticated(let user):
                MainTabView(user: user)
                    .environmentObject(authManager)
                
            case .unauthenticated:
                AuthenticationFlowView()
                    .environmentObject(authManager)
                
            case .error(let error):
                ErrorView(message: error.localizedDescription) {
                    Task {
                        await authManager.checkAuthenticationStatus()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: AppConfig.UI.animationDuration), value: authManager.authState)
        .task {
            await authManager.checkAuthenticationStatus()
        }
    }
}


