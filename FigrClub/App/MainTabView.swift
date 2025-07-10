//
//  MainTabView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var tabCoordinator = CoordinatorFactory.makeMainTabCoordinator()
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    var body: some View {
        if case .authenticated(let user) = authStateManager.authState {
            TabView(selection: $tabCoordinator.selectedTab) {
                // Feed Tab - usando coordinador para navegación futura
                FeedFlowView(user: user)
                    .environmentObject(tabCoordinator.feedCoordinator)
                    .tabItem {
                        Image(systemName: MainTab.feed.icon)
                        Text(MainTab.feed.title)
                    }
                    .tag(MainTab.feed)
                
                // TODO
                /*
                 // Marketplace Tab
                 MarketplaceFlowView(user: user)
                 .environmentObject(tabCoordinator.marketplaceCoordinator)
                 .tabItem {
                 Image(systemName: MainTab.marketplace.icon)
                 Text(MainTab.marketplace.title)
                 }
                 .tag(MainTab.marketplace)
                 
                 // Create Tab
                 CreateFlowView(user: user)
                 .environmentObject(tabCoordinator.createCoordinator)
                 .tabItem {
                 Image(systemName: MainTab.create.icon)
                 Text(MainTab.create.title)
                 }
                 .tag(MainTab.create)
                 
                 // Notifications Tab
                 NotificationsFlowView(user: user)
                 .environmentObject(tabCoordinator.notificationsCoordinator)
                 .tabItem {
                 Image(systemName: MainTab.notifications.icon)
                 Text(MainTab.notifications.title)
                 }
                 .tag(MainTab.notifications)
                 
                 */
                
                // Profile Tab
                ProfileFlowView(user: user)
                    .environmentObject(tabCoordinator.profileCoordinator)
                    .tabItem {
                        Image(systemName: MainTab.profile.icon)
                        Text(MainTab.profile.title)
                    }
                    .tag(MainTab.profile)
            }
            .environmentObject(tabCoordinator)
            .onOpenURL { url in
                DeepLinkManager.shared.handleDeepLink(url, coordinator: tabCoordinator)
            }
        } else {
            // Fallback en caso de que no haya usuario autenticado
            LoadingView()
        }
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

