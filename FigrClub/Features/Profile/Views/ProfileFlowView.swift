//
//  ProfileFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI

struct ProfileFlowView: View {
    let user: User
    @EnvironmentObject private var coordinator: ProfileCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    // Estado para el botón de logout
    @State private var isLoggingOut = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                // Header del perfil
                profileHeaderView
                
                // Información del usuario
                userInfoSection
                
                // Botones de acciones del perfil
                profileActionsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - Profile Header
    
    private var profileHeaderView: some View {
        VStack(spacing: Spacing.medium) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(user.displayName.prefix(1).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                )
            
            // Verificación
            if user.isVerified {
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                    Text("Verificado")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        VStack(spacing: Spacing.small) {
            Text(user.displayName)
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(user.fullName)
                .font(.callout)
                .foregroundColor(.secondary)
            
            Text(user.email)
                .font(.callout)
                .foregroundColor(.secondary)
            
            // Stats
            HStack(spacing: Spacing.xLarge) {
                statView(title: "Posts", count: user.postsCount)
                statView(title: "Siguiendo", count: user.followingCount)
                statView(title: "Seguidores", count: user.followersCount)
            }
            .padding(.top, Spacing.medium)
        }
    }
    
    // MARK: - Profile Actions Section
    
    private var profileActionsSection: some View {
        VStack(spacing: Spacing.medium) {
            // Botón de editar perfil
            Button("Editar Perfil") {
                coordinator.showEditProfile()
            }
            .buttonStyle(FigrButtonStyle(isEnabled: true))
            
            // Botón de configuración
            Button("Configuración") {
                coordinator.showSettings()
            }
            .buttonStyle(FigrButtonStyle(isEnabled: true))
            
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
            .buttonStyle(FigrButtonStyle(isEnabled: !isLoggingOut, isLoading: isLoggingOut))
            .disabled(isLoggingOut)
        }
        .padding(.top, Spacing.large)
    }
    
    // MARK: - Helper Views
    
    private func statView(title: String, count: Int) -> some View {
        VStack(spacing: Spacing.xxSmall) {
            Text("\(count)")
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Private Methods
    
    private func performLogout() {
        guard !isLoggingOut else { return }
        
        isLoggingOut = true
        showLogoutConfirmation = false
        
        Logger.info("🚪 ProfileFlowView: Starting logout process for user: \(user.displayName)")
        
        Task {
            do {
                // Usar el método logout del AuthStateManager directamente
                await authStateManager.logout()
                
                Logger.info("✅ ProfileFlowView: Logout completed successfully")
                
                // El estado de carga se resetea automáticamente cuando cambia authState
                
            } catch {
                // En caso de error, resetear el estado de carga
                await MainActor.run {
                    isLoggingOut = false
                }
                
                Logger.error("❌ ProfileFlowView: Logout failed: \(error)")
            }
        }
    }
}
