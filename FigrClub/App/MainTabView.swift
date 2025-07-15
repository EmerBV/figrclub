//
//  MainTabView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct MainTabView: View {
    let user: User
    
    @EnvironmentObject private var authStateManager: AuthStateManager
    @StateObject private var navigationCoordinator = CoordinatorFactory.makeNavigationCoordinator()
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    
    // Estado local para el tab seleccionado
    @State private var selectedTab: MainTab = .feed
    
    var body: some View {
        Group {
            if authStateManager.isAuthenticated {
                tabContent
            } else {
                EBVLoadingView.appLaunch
                    .onAppear {
                        Logger.warning("⚠️ MainTabView: Rendered without authentication, user: \(user.displayName)")
                        // Intentar reautenticar o navegar de vuelta a auth
                        Task {
                            await authStateManager.checkInitialAuthState()
                        }
                    }
            }
        }
    }
    
    // MARK: - Tab Content
    
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            // Feed Tab
            FeedFlowView(user: user)
                .tabItem {
                    Image(systemName: MainTab.feed.icon)
                    Text(MainTab.feed.title)
                }
                .tag(MainTab.feed)
            
            // Marketplace Tab
            MarketplaceFlowView(user: user)
                .tabItem {
                    Image(systemName: MainTab.marketplace.icon)
                    Text(MainTab.marketplace.title)
                }
                .tag(MainTab.marketplace)
            
            // Create Tab
            CreateFlowView(user: user)
                .tabItem {
                    Image(systemName: MainTab.create.icon)
                    Text(MainTab.create.title)
                }
                .tag(MainTab.create)
            
            // Notifications Tab
            NotificationsFlowView(user: user)
                .tabItem {
                    Image(systemName: MainTab.notifications.icon)
                    Text(MainTab.notifications.title)
                }
                .tag(MainTab.notifications)
            
            // Profile Tab
            ProfileFlowView(user: user)
                .tabItem {
                    Image(systemName: MainTab.profile.icon)
                    Text(MainTab.profile.title)
                }
                .tag(MainTab.profile)
        }
        .environmentObject(navigationCoordinator)
        .onAppear {
            setupDeepLinkManager()
            Logger.debug("✅ MainTabView: Appeared with user: \(user.displayName)")
        }
        .onOpenURL { url in
            deepLinkManager.handleURL(url)
        }
        // Sincronizar con DeepLinkManager solo cuando sea necesario
        .onChange(of: deepLinkManager.selectedTab) { oldValue, newValue in
            Logger.debug("🔄 MainTabView: DeepLink changed tab from \(oldValue.title) to \(newValue.title)")
            selectedTab = newValue
        }
        // Actualizar DeepLinkManager cuando el usuario cambie tab manualmente
        .onChange(of: selectedTab) { oldValue, newValue in
            Logger.debug("🔄 MainTabView: User changed tab from \(oldValue.title) to \(newValue.title)")
            deepLinkManager.selectedTab = newValue
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDeepLinkManager() {
        // Setup deep link manager con navigation coordinator
        deepLinkManager.setup(navigationCoordinator: navigationCoordinator)
        deepLinkManager.processPendingDeepLinkIfNeeded()
        
        Logger.debug("✅ MainTabView: DeepLinkManager setup completed")
    }
}

/*
 // MARK: - Preview
 #if DEBUG
 struct MainTabView_Previews: PreviewProvider {
 static var previews: some View {
 let sampleUser = User(
 id: 1,
 firstName: "John",
 lastName: "Doe",
 email: "john@example.com",
 username: "johndoe",
 userType: "REGULAR",
 subscriptionType: "FREE",
 isVerified: true,
 profileImageUrl: nil,
 bio: "Sample user bio",
 createdAt: Date(),
 updatedAt: Date()
 )
 
 MainTabView(user: sampleUser)
 .environmentObject(DependencyInjector.shared.resolve(AuthStateManager.self))
 }
 }
 #endif
 */

