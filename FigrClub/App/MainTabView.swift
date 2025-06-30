//
//  MainTabView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authManager = DependencyContainer.shared.resolve(AuthManager.self)
    @State private var selectedTab: Tab = .feed
    @State private var showingNewPost = false
    @State private var badgeCount = 0
    
    enum Tab: Int, CaseIterable {
        case feed = 0
        case marketplace = 1
        case create = 2
        case notifications = 3
        case profile = 4
        
        var title: String {
            switch self {
            case .feed: return "Feed"
            case .marketplace: return "Marketplace"
            case .create: return "Crear"
            case .notifications: return "Notificaciones"
            case .profile: return "Perfil"
            }
        }
        
        var iconName: String {
            switch self {
            case .feed: return "house"
            case .marketplace: return "cart"
            case .create: return "plus.circle"
            case .notifications: return "bell"
            case .profile: return "person.circle"
            }
        }
        
        var selectedIconName: String {
            switch self {
            case .feed: return "house.fill"
            case .marketplace: return "cart.fill"
            case .create: return "plus.circle.fill"
            case .notifications: return "bell.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Feed Tab
            FeedView()
                .tabItem {
                    Image(systemName: selectedTab == .feed ? Tab.feed.selectedIconName : Tab.feed.iconName)
                    Text(Tab.feed.title)
                }
                .tag(Tab.feed)
            
            // Marketplace Tab
            MarketplaceView()
                .tabItem {
                    Image(systemName: selectedTab == .marketplace ? Tab.marketplace.selectedIconName : Tab.marketplace.iconName)
                    Text(Tab.marketplace.title)
                }
                .tag(Tab.marketplace)
            
            // Create Tab (Special handling)
            Color.clear
                .tabItem {
                    Image(systemName: Tab.create.iconName)
                    Text(Tab.create.title)
                }
                .tag(Tab.create)
            
            // Notifications Tab
            NotificationsView()
                .tabItem {
                    Image(systemName: selectedTab == .notifications ? Tab.notifications.selectedIconName : Tab.notifications.iconName)
                    Text(Tab.notifications.title)
                }
                .badge(badgeValue)
                .tag(Tab.notifications)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? Tab.profile.selectedIconName : Tab.profile.iconName)
                    Text(Tab.profile.title)
                }
                .tag(Tab.profile)
        }
        .accentColor(.figrPrimary)
        .onChange(of: selectedTab) { newTab in
            handleTabSelection(newTab)
        }
        .sheet(isPresented: $showingNewPost) {
            CreatePostView()
        }
        .onAppear {
            setupTabBarAppearance()
            Analytics.shared.logScreenView(screenName: "MainTabView")
        }
    }
    
    private var badgeValue: String? {
        return badgeCount > 0 ? "\(badgeCount)" : nil
    }
    
    // MARK: - Private Methods
    
    private func handleTabSelection(_ tab: Tab) {
        // Handle special create tab
        if tab == .create {
            showingNewPost = true
            // Reset to previous tab
            selectedTab = .feed
            return
        }
        
        // Log analytics
        Analytics.shared.logEvent("tab_changed", parameters: [
            "previous_tab": selectedTab.title,
            "new_tab": tab.title
        ])
        
        // Haptic feedback
        HapticManager.shared.selection()
        
        // Update badge count for notifications tab
        if tab == .notifications {
            badgeCount = 0
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(.figrSurface)
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(.figrTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(.figrTextSecondary)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.figrPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(.figrPrimary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.figrTextSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(.figrSurface)
        .cornerRadius(CornerRadius.medium)
    }
}

// MARK: - Preview
#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .dependencyInjection()
    }
}
#endif

