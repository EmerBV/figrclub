//
//  FeedFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI
import Kingfisher

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
                // Avatar del usuario actual usando KFImage
                if user.hasProfileImage {
                    KFImage(URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(user.id)/profile"))
                        .profileImageStyle(size: 50)
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(user.displayName.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                        )
                }
                
                VStack(alignment: .leading) {
                    Text("¡Hola, \(user.displayName)!")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Bienvenido a FigrClub")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Botón de notificaciones
                Button {
                    // TODO: Navegar a notificaciones
                } label: {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
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
            // Demo de posts usando Kingfisher
            samplePostsView
            
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
    
    private var samplePostsView: some View {
        VStack(spacing: Spacing.medium) {
            // Post de ejemplo 1
            VStack(alignment: .leading, spacing: 12) {
                // Header del post
                HStack {
                    KFImage(URL(string: "https://picsum.photos/seed/user1/200/200"))
                        .profileImageStyle(size: 40)
                    
                    VStack(alignment: .leading) {
                        Text("Ana García")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Text("Hace 2 horas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Contenido del post
                Text("¡Acabo de conseguir esta increíble figura de edición limitada! 🔥")
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Imagen del post usando las extensiones de Kingfisher
                KFImage(URL(string: "https://picsum.photos/seed/figure1/400/400"))
                    .postImageStyle()
                    .frame(height: 200)
                
                // Acciones del post
                HStack(spacing: 20) {
                    Button {
                        Logger.info("❤️ Like tapped")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                            Text("42")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        Logger.info("💬 Comment tapped")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .foregroundColor(.primary)
                            Text("8")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        Logger.info("📤 Share tapped")
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            
            // Post de ejemplo 2 - Solo avatar
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    KFImage(URL(string: "https://picsum.photos/seed/user2/200/200"))
                        .profileImageStyle(size: 40)
                    
                    VStack(alignment: .leading) {
                        Text("Carlos López")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Text("Hace 4 horas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text("¿Qué opinan de mi nueva colección de figuras de anime? 🎌")
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Grid de thumbnails
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    let url = URL(string: "https://picsum.photos/seed/anime0/200/200")
                    
                    ForEach(0..<6) { index in
                        OptimizedImageGridCell(
                            url: url,
                            size: 80,
                            onTap: {
                                Logger.info("📱 Thumbnail \(index) tapped")
                            }
                        )
                        
                        /*
                        KFImage(URL(string: "https://picsum.photos/seed/anime\(index)/200/200"))
                            .thumbnailStyle(size: 80)
                            .onTapGesture {
                                Logger.info("📱 Thumbnail \(index) tapped")
                            }
                         */
                    }
                }
                
                
                HStack(spacing: 20) {
                    Button {
                        Logger.info("❤️ Like tapped")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("127")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        Logger.info("💬 Comment tapped")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .foregroundColor(.primary)
                            Text("23")
                                .font(.caption)
                        }
                    }
                    
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
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
