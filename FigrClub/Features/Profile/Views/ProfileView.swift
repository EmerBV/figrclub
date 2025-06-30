//
//  ProfileView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var viewModel = DependencyContainer.shared.resolve(ProfileViewModel.self)
    @StateObject private var authManager = DependencyContainer.shared.resolve(AuthManager.self)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Profile Header
                    ProfileHeaderView(user: authManager.currentUser)
                    
                    // Stats Section
                    if let stats = viewModel.userStats {
                        ProfileStatsView(stats: stats)
                    }
                    
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

// MARK: - Missing View Stubs
struct EditProfileView: View {
    var body: some View {
        Text("Editar Perfil")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Configuración")
    }
}

// MARK: - Preview
#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .dependencyInjection()
    }
}
#endif
