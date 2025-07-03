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
                MainTabView()
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
        .onAppear {
            setupGlobalAppearance()
        }
    }
    
    private func setupGlobalAppearance() {
        // Configure global UI appearance
        setupNavigationBarAppearance()
        setupTabBarAppearance()
    }
    
    private func setupNavigationBarAppearance() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.backgroundColor = UIColor(.figrBackground)
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(.figrTextPrimary),
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(.figrTextPrimary),
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    }
    
    private func setupTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor(.figrSurface)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

extension ContentView {
    var mainTabView: some View {
        TabView {
            NavigationView {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: "house.fill")
            }
            
            NavigationView {
                MarketplaceView()
            }
            .tabItem {
                Label("Marketplace", systemImage: "cart.fill")
            }
            
            NavigationView {
                CreatePostView()
            }
            .tabItem {
                Label("Crear", systemImage: "plus.circle.fill")
            }
            
            NavigationView {
                NotificationsView()
            }
            .tabItem {
                Label("Notificaciones", systemImage: "bell.fill")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.fill")
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

// MARK: - Button Style
struct FigrButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.figrCallout.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(
                isEnabled ? Color.figrPrimary : Color.figrTextSecondary
            )
            .cornerRadius(AppConfig.UI.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Preview
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DependencyContainer.shared.resolve(AuthManager.self))
    }
}
#endif

