//
//  FeedFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI

struct FeedFlowView: View {
    let user: User
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    // Estado local para UI
    @State private var isLoggingOut = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Header
                    headerView
                    
                    // Content
                    contentView
                    
                    // Actions
                    actionsView
                }
                .padding()
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Implementar refresh del feed
                await refreshFeed()
            }
        }
        // Navegación modal
        .sheet(isPresented: $navigationCoordinator.showingPostDetail) {
            if let postId = navigationCoordinator.selectedPostId {
                PostDetailSheet(postId: postId, user: user)
            }
        }
        .sheet(isPresented: $navigationCoordinator.showingUserProfile) {
            if let userId = navigationCoordinator.selectedUserId {
                UserProfileSheet(userId: userId, currentUser: user)
            }
        }
        // Alert de confirmación para logout
        .alert("Cerrar Sesión", isPresented: $showLogoutConfirmation) {
            Button("Cancelar", role: .cancel) {
                showLogoutConfirmation = false
            }
            
            Button("Cerrar Sesión", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("¿Estás seguro de que quieres cerrar tu sesión?")
        }
        // Observar estado de autenticación
        .onChange(of: authStateManager.authState) { oldValue, newValue in
            if case .unauthenticated = newValue {
                isLoggingOut = false
            }
        }
        .onAppear {
            Logger.info("✅ FeedFlowView: Appeared for user: \(user.username)")
        }
    }
    
    // MARK: - Private Views
    
    private var headerView: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("¡Hola, \(user.displayName)!")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Bienvenido a FigrClub")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var contentView: some View {
        VStack(spacing: Spacing.medium) {
            Text("Tu feed estará aquí pronto")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Mientras tanto, puedes explorar las funciones disponibles")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemFill))
        )
    }
    
    private var actionsView: some View {
        VStack(spacing: Spacing.medium) {
            // Botones de navegación de ejemplo
            Button("Ver Post de Ejemplo") {
                navigationCoordinator.showPostDetail("post_123")
            }
            .buttonStyle(EBVPrimaryBtnStyle())
            
            Button("Ver Perfil de Usuario") {
                navigationCoordinator.showUserProfile("user_456")
            }
            .buttonStyle(EBVPrimaryBtnStyle())
            
            // Separador
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
                .padding(.vertical, Spacing.small)
            
            // Botón de cerrar sesión
            Button {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    if isLoggingOut {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Cerrando sesión...")
                    } else {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar Sesión")
                    }
                }
            }
            .buttonStyle(EBVPrimaryBtnStyle(isEnabled: !isLoggingOut, isLoading: isLoggingOut))
            .disabled(isLoggingOut)
        }
    }
    
    // MARK: - Private Methods
    
    private func performLogout() {
        guard !isLoggingOut else { return }
        
        isLoggingOut = true
        showLogoutConfirmation = false
        
        Logger.info("🚪 FeedFlowView: Starting logout process for user: \(user.username)")
        
        Task {
            await authStateManager.logout()
            Logger.info("✅ FeedFlowView: Logout completed successfully")
        }
    }
    
    private func refreshFeed() async {
        Logger.info("🔄 FeedFlowView: Refreshing feed")
        
        // Simular carga
        try? await Task.sleep(for: .seconds(1))
        
        Logger.info("✅ FeedFlowView: Feed refreshed")
    }
}

// MARK: - Supporting Views

struct PostDetailSheet: View {
    let postId: String
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.large) {
                Text("Post Detail")
                    .font(.title)
                
                Text("Post ID: \(postId)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Esta funcionalidad estará disponible pronto")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UserProfileSheet: View {
    let userId: String
    let currentUser: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.large) {
                Text("User Profile")
                    .font(.title)
                
                Text("User ID: \(userId)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Esta funcionalidad estará disponible pronto")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
