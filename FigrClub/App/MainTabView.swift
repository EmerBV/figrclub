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
                .badge(badgeCount > 0 ? badgeCount : nil)
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

// MARK: - Feed View
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        LoadingView(message: "Cargando posts...")
                    } else if viewModel.posts.isEmpty {
                        EmptyStateView(
                            title: "No hay posts",
                            message: "Sé el primero en compartir algo increíble",
                            imageName: "doc.text",
                            buttonTitle: "Crear Post"
                        ) {
                            // Handle create post
                        }
                    } else {
                        ForEach(viewModel.posts) { post in
                            PostCardView(post: post)
                                .onAppear {
                                    if post == viewModel.posts.last {
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                                }
                        }
                        
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
                await viewModel.refreshPosts()
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadPosts()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "FeedView")
        }
    }
}

// MARK: - Marketplace View
struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $viewModel.searchText, placeholder: "Buscar productos...")
                    .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.small) {
                        ForEach(viewModel.categories) { category in
                            CategoryChip(
                                category: category,
                                isSelected: viewModel.selectedCategory?.id == category.id
                            ) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Items Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.medium) {
                        ForEach(viewModel.items) { item in
                            MarketplaceItemCard(item: item)
                                .onAppear {
                                    if item == viewModel.items.last {
                                        Task {
                                            await viewModel.loadMoreItems()
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    await viewModel.refreshItems()
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Handle create item
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            await viewModel.loadItems()
            await viewModel.loadCategories()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "MarketplaceView")
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notifications) { notification in
                    NotificationRowView(notification: notification)
                        .onTapGesture {
                            viewModel.markAsRead(notification)
                        }
                }
                .onDelete(perform: viewModel.deleteNotifications)
            }
            .refreshable {
                await viewModel.refreshNotifications()
            }
            .navigationTitle("Notificaciones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Marcar como leídas") {
                        viewModel.markAllAsRead()
                    }
                    .disabled(viewModel.notifications.isEmpty)
                }
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "NotificationsView")
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var authManager = DependencyContainer.shared.resolve(AuthManager.self)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Profile Header
                    ProfileHeaderView(user: authManager.currentUser)
                    
                    // Stats Section
                    ProfileStatsView(stats: viewModel.userStats)
                    
                    // Action Buttons
                    VStack(spacing: Spacing.medium) {
                        FigrButton(title: "Editar Perfil", style: .secondary) {
                            viewModel.showEditProfile = true
                        }
                        
                        FigrButton(title: "Configuración", style: .ghost) {
                            viewModel.showSettings = true
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // User Posts
                    LazyVStack(spacing: Spacing.medium) {
                        ForEach(viewModel.userPosts) { post in
                            PostCardView(post: post)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Compartir Perfil") {
                            viewModel.shareProfile()
                        }
                        
                        Button("Configuración") {
                            viewModel.showSettings = true
                        }
                        
                        Divider()
                        
                        Button("Cerrar Sesión", role: .destructive) {
                            authManager.logout()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        .task {
            await viewModel.loadUserData()
            await viewModel.loadUserPosts()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "ProfileView")
        }
    }
}

// MARK: - Create Post View
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                // Content Input
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("¿Qué quieres compartir?")
                        .font(.figrHeadline)
                        .foregroundColor(.figrTextPrimary)
                    
                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 150)
                        .padding()
                        .background(.figrSurface)
                        .cornerRadius(CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(.figrBorder, lineWidth: 1)
                        )
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: Spacing.medium) {
                    FigrButton(
                        title: "Publicar",
                        isLoading: viewModel.isPosting,
                        isEnabled: !viewModel.content.isEmpty
                    ) {
                        Task {
                            await viewModel.createPost()
                            if viewModel.postCreated {
                                dismiss()
                            }
                        }
                    }
                    
                    FigrButton(title: "Cancelar", style: .ghost) {
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationTitle("Crear Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "CreatePostView")
        }
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

