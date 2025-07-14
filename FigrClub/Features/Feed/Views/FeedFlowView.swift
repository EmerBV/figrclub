//
//  FeedFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI

struct FeedFlowView: View {
    let user: User
    @EnvironmentObject private var coordinator: FeedCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    // Estado para el botón de logout
    @State private var isLoggingOut = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Feed")
                    .font(.largeTitle.weight(.bold))
                
                Text("Bienvenido, \(user.username)!")
                    .font(.title2)
                
                // Botones de ejemplo para mostrar navegación con coordinator
                VStack(spacing: 12) {
                    Button("Ver Post de Ejemplo") {
                        coordinator.showPostDetail("post_123")
                    }
                    .buttonStyle(FigrButtonStyle())
                    
                    Button("Ver Perfil de Usuario") {
                        coordinator.showUserProfile("user_456")
                    }
                    .buttonStyle(FigrButtonStyle())
                    
                    // Botón de cerrar sesión mejorado con confirmación y estado de carga
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
                    .buttonStyle(FigrButtonStyle(isEnabled: !isLoggingOut, isLoading: isLoggingOut))
                    .disabled(isLoggingOut)
                }
                .padding()
            }
            .navigationTitle("FigrClub")
        }
        // Navegación usando sheets por ahora (se puede cambiar a NavigationStack después)
        .sheet(isPresented: $coordinator.showingPostDetail) {
            if let postId = coordinator.selectedPostId {
                NavigationView {
                    //PostDetailView(postId: postId, user: user)
                }
            }
        }
        .sheet(isPresented: $coordinator.showingUserProfile) {
            if let userId = coordinator.selectedUserId {
                NavigationView {
                    //UserProfileView(userId: userId, currentUser: user)
                }
            }
        }
        .sheet(isPresented: $coordinator.showingComments) {
            if let postId = coordinator.commentsPostId {
                NavigationView {
                    //CommentsView(postId: postId, user: user)
                }
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
        // Observar estado de autenticación para resetear UI
        .onReceive(authStateManager.$authState) { authState in
            if case .unauthenticated = authState {
                isLoggingOut = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performLogout() {
        guard !isLoggingOut else { return }
        
        isLoggingOut = true
        showLogoutConfirmation = false
        
        Logger.info("🚪 FeedFlowView: Starting logout process for user: \(user.username)")
        
        Task {
            do {
                // Usar el método logout del AuthStateManager directamente
                await authStateManager.logout()
                
                Logger.info("✅ FeedFlowView: Logout completed successfully")
                
                // El estado de carga se resetea automáticamente cuando cambia authState
                
            } catch {
                // En caso de error, resetear el estado de carga
                await MainActor.run {
                    isLoggingOut = false
                }
                
                Logger.error("❌ FeedFlowView: Logout failed: \(error)")
                
                // Mostrar error al usuario si es necesario
                // TODO: Mostrar alert de error si se requiere
            }
        }
    }
}
