//
//  MainTabView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI
import Kingfisher

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
                customTabView
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
    
    // MARK: - Custom Tab View
    
    private var customTabView: some View {
        VStack(spacing: 0) {
            // Content Area
            Group {
                switch selectedTab {
                case .feed:
                    FeedFlowView(user: user)
                case .marketplace:
                    MarketplaceFlowView(user: user)
                case .create:
                    CreateFlowView(user: user)
                case .notifications:
                    NotificationsFlowView(user: user)
                case .profile:
                    ProfileFlowView(user: user)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            customTabBar
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
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.id) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        // Tab Icon
                        if tab == .profile {
                            profileTabIcon
                        } else {
                            regularTabIcon(for: tab)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
        )
        .overlay(
            // Top border
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
            , alignment: .top
        )
    }
    
    // MARK: - Tab Icons
    
    @ViewBuilder
    private func regularTabIcon(for tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        let iconName = isSelected ? tab.selectedIcon : tab.icon
        
        Image(systemName: iconName)
            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    // MARK: - Profile Tab Icon
    
    @ViewBuilder
    private var profileTabIcon: some View {
        let isSelected = selectedTab == .profile
        let iconSize: CGFloat = 26
        
        Group {
            if user.hasProfileImage {
                // Imagen de perfil del servidor
                KFImage(URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(user.id)/profile"))
                    .setProcessor(
                        RoundCornerImageProcessor(cornerRadius: iconSize / 2)
                        |> DownsamplingImageProcessor(size: CGSize(width: iconSize * 2, height: iconSize * 2))
                    )
                    .placeholder {
                        // Placeholder mientras carga
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: iconSize, height: iconSize)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                            )
                    }
                    .onFailure { error in
                        Logger.warning("⚠️ Profile tab icon failed to load: \(error.localizedDescription)")
                    }
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(Circle())
            } else {
                // Placeholder con iniciales del usuario
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    )
            }
        }
        .overlay(
            // Border de selección
            Circle()
                .stroke(
                    isSelected ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
                .frame(width: iconSize + 4, height: iconSize + 4)
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    // MARK: - Private Methods
    
    private func setupDeepLinkManager() {
        // Setup deep link manager con navigation coordinator
        deepLinkManager.setup(navigationCoordinator: navigationCoordinator)
        deepLinkManager.processPendingDeepLinkIfNeeded()
        
        Logger.debug("✅ MainTabView: DeepLinkManager setup completed")
    }
}

