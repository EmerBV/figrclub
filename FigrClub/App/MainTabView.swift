//
//  MainTabView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authStateManager: AuthStateManager
    @StateObject private var navigationCoordinator = CoordinatorFactory.makeNavigationCoordinator()
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    
    var body: some View {
        if case .authenticated(let user) = authStateManager.authState {
            TabView(selection: $deepLinkManager.selectedTab) {
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
                // Setup deep link manager with navigation coordinator
                deepLinkManager.setup(navigationCoordinator: navigationCoordinator)
                deepLinkManager.processPendingDeepLinkIfNeeded()
            }
            .onOpenURL { url in
                deepLinkManager.handleURL(url)
            }
            .onChange(of: deepLinkManager.selectedTab) { oldValue, newValue in
                Logger.debug("🔄 MainTabView: Tab changed from \(oldValue.title) to \(newValue.title)")
            }
        } else {
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

