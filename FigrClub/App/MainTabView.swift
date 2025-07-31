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
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var navigationCoordinator = CoordinatorFactory.makeNavigationCoordinator()
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    
    // Estado local para el tab seleccionado
    @State private var selectedTab: MainTab = .feed
    @State private var lastNonCreateTab: MainTab = .feed
    
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
                    AnyView(FeedFlowView(user: user))
                case .marketplace:
                    AnyView(MarketplaceFlowView(user: user))
                case .create:
                    // Mostrar la última pestaña seleccionada cuando se presiona Create
                    // El contenido real se presenta como modal
                    AnyView(
                        Group {
                            switch lastNonCreateTab {
                            case .feed:
                                FeedFlowView(user: user)
                            case .marketplace:
                                MarketplaceFlowView(user: user)
                            case .notifications:
                                NotificationsFlowView(user: user)
                            case .profile:
                                ProfileFlowView(user: user)
                            case .create:
                                FeedFlowView(user: user) // Fallback
                            }
                        }
                    )
                case .notifications:
                    AnyView(NotificationsFlowView(user: user))
                case .profile:
                    AnyView(ProfileFlowView(user: user))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            //.background(themeManager.currentBackgroundColor)
            
            // Custom Tab Bar
            customTabBar
        }
        /*
        .background(
            // Fondo que se extiende hasta el bottom safe area
            themeManager.currentBackgroundColor
                .ignoresSafeArea(.container, edges: .bottom)
        )
         */
        
        .themedBackground()
        .environmentObject(navigationCoordinator)
        .fullScreenCover(isPresented: $navigationCoordinator.showingCreatePost) {
            CreateFlowView(user: user)
                .environmentObject(themeManager)
                .environmentObject(navigationCoordinator)
                .environmentObject(DependencyInjector.shared.resolve(CameraManager.self))
                .environmentObject(DependencyInjector.shared.resolve(HapticFeedbackManager.self))
        }
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
    
    // MARK: - Helper Methods
    
    private func handleTabSelection(_ tab: MainTab) {
        if tab == .create {
            // Mostrar modal de creación en lugar de cambiar tab
            navigationCoordinator.showCreatePost()
        } else {
            // Cambiar tab normalmente y recordar la última pestaña no-create
            withAnimation(.easeInOut(duration: 0.2)) {
                lastNonCreateTab = selectedTab != .create ? selectedTab : lastNonCreateTab
                selectedTab = tab
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(themeManager.colorScheme == .dark ? Color.figrDarkTextTertiary.opacity(0.2) : Color(.separator))
                .frame(height: 0.5)
            
            // Tab bar content
            HStack {
                ForEach(MainTab.allCases, id: \.id) { tab in
                    Button(action: {
                        handleTabSelection(tab)
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
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.top, AppTheme.Spacing.small)
            .padding(.bottom, AppTheme.Spacing.small)
        }
        //.background(themeManager.currentCardColor)
        .shadow(
            color: themeManager.colorScheme == .dark ?
            AppTheme.Shadow.cardShadowColor.opacity(0.3) :
                AppTheme.Shadow.cardShadowColor,
            radius: AppTheme.Shadow.cardShadow.radius,
            x: AppTheme.Shadow.cardShadow.x,
            y: AppTheme.Shadow.cardShadow.y
        )
    }
    
    // MARK: - Tab Icons
    
    @ViewBuilder
    private func regularTabIcon(for tab: MainTab) -> some View {
        // Create tab nunca se marca como seleccionado visualmente
        let isSelected = tab == .create ? false : selectedTab == tab
        let iconName = isSelected ? tab.selectedIcon : tab.icon
        
        Image(systemName: iconName)
            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.currentSecondaryTextColor)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(AppTheme.Animation.quick, value: isSelected)
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
                            .fill(themeManager.currentSecondaryTextColor.opacity(0.3))
                            .frame(width: iconSize, height: iconSize)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .tint(themeManager.accentColor)
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
                    .fill(themeManager.accentColor.opacity(0.2))
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                    )
            }
        }
        .overlay(
            // Border de selección temático
            Circle()
                .stroke(
                    isSelected ? themeManager.accentColor : Color.clear,
                    lineWidth: 2
                )
                .frame(width: iconSize + 4, height: iconSize + 4)
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(AppTheme.Animation.quick, value: isSelected)
    }
    
    // MARK: - Private Methods
    
    private func setupDeepLinkManager() {
        // Setup deep link manager con navigation coordinator
        deepLinkManager.setup(navigationCoordinator: navigationCoordinator)
        deepLinkManager.processPendingDeepLinkIfNeeded()
        
        Logger.debug("✅ MainTabView: DeepLinkManager setup completed")
    }
}

