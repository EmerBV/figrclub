//
//  ProfileFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI
import Kingfisher

struct ProfileFlowView: View {
    let user: User
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var isLoggingOut = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header con información del usuario
                    headerSection
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.large)
                    
                    // Lista de opciones
                    optionsSection
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .themedBackground()
        }
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
        .sheet(isPresented: $navigationCoordinator.showingSettings) {
            SettingsView(user: user)
        }
        .sheet(isPresented: $navigationCoordinator.showingUserProfileDetail) {
                    if let selectedUser = navigationCoordinator.selectedUserForDetail {
                        UserProfileDetailView(user: selectedUser)
                    }
                }
        .sheet(isPresented: $navigationCoordinator.showingEditProfile) {
            EditProfileView(user: user)
        }
        .onReceive(authStateManager.$authState) { authState in
            if case .unauthenticated = authState {
                isLoggingOut = false
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                // Imagen de perfil
                profileImageView
                
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    // Nombre y verificación
                    HStack(spacing: Spacing.xSmall) {
                        Text(user.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Rating con estrellas
                    HStack(spacing: Spacing.xxSmall) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        
                        Text("\(user.followersCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Fecha de registro
                    Text("En FigrClub desde \(extractYear(from: user.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Botón de navegación
                Button(action: {
                    navigationCoordinator.showUserProfileDetail(user: user)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(.top, Spacing.xLarge)
    }
    
    // MARK: - Profile Image View
    private var profileImageView: some View {
        let imageURL = URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(user.id)/profile")
        
        return Group {
            if user.hasProfileImage {
                KFImage(imageURL)
                    .setProcessor(
                        RoundCornerImageProcessor(cornerRadius: 30)
                        |> DownsamplingImageProcessor(size: CGSize(width: 120, height: 120))
                    )
                    .placeholder {
                        Circle()
                            .fill(themeManager.currentSecondaryTextColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(themeManager.accentColor)
                            )
                    }
                    .onFailure { error in
                        Logger.warning("⚠️ Profile image failed to load: \(error.localizedDescription)")
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                    )
            }
        }
    }
    
    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(spacing: 0) {
            // Sección CONTENIDO
            sectionHeader("CONTENIDO")
            
            optionRow(
                icon: "square.grid.3x3.fill",
                title: "Mis Posts",
                action: { /* Navegar a mis posts */ }
            )
            
            optionRow(
                icon: "play.rectangle.fill",
                title: "Mis Reels",
                action: { /* Navegar a mis reels */ }
            )
            
            optionRow(
                icon: "dot.radiowaves.left.and.right",
                title: "Mis Directos",
                action: { /* Navegar a mis directos */ }
            )
            
            // Sección TRANSACCIONES
            sectionHeader("TRANSACCIONES")
            
            optionRow(
                icon: "cart.fill",
                title: "Compras",
                action: { /* Navegar a compras */ }
            )
            
            optionRow(
                icon: "tag.fill",
                title: "Ventas",
                action: { /* Navegar a ventas */ }
            )
            
            optionRow(
                icon: "creditcard.fill",
                title: "Monedero",
                action: { /* Navegar a monedero */ }
            )
            
            optionRow(
                icon: "leaf.fill",
                title: "Tu impacto positivo",
                action: { /* Navegar a impacto */ }
            )
            
            // Sección CUENTA
            sectionHeader("CUENTA")
            
            optionRow(
                icon: "star.fill",
                title: "FigrClub PRO",
                action: { /* Navegar a PRO */ }
            )
            
            optionRow(
                icon: "heart.fill",
                title: "Favoritos",
                action: { /* Navegar a favoritos */ }
            )
            
            optionRow(
                icon: "gearshape.fill",
                title: "Configuración",
                action: { navigationCoordinator.showSettings() }
            )
            
            // Sección FIGRCLUB AL HABLA
            sectionHeader("FIGRCLUB AL HABLA")
            
            optionRow(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Chat de la comunidad",
                action: { /* Navegar a chat */ }
            )
            
            // Botón de cerrar sesión
            logoutButton
                .padding(.bottom, Spacing.xLarge)
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.large)
        .padding(.bottom, Spacing.small)
    }
    
    // MARK: - Option Row
    private func optionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
            .background(
                Rectangle()
                    .fill(themeManager.currentBackgroundColor)
                    .contentShape(Rectangle())
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: Spacing.medium) {
                if isLoggingOut {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        .scaleEffect(0.8)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                }
                
                Text(isLoggingOut ? "Cerrando sesión..." : "Cerrar Sesión")
                    .font(.body)
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoggingOut)
        .padding(.top, Spacing.medium)
    }
    
    // MARK: - Helper Methods
    
    private func extractYear(from dateString: String) -> String {
        // Extraer el año de un string con formato "2025-07-17 11:13:16"
        let components = dateString.components(separatedBy: "-")
        return components.first ?? "2025" // Fallback al año actual si no se puede extraer
    }
    
    private func performLogout() {
        guard !isLoggingOut else { return }
        
        isLoggingOut = true
        showLogoutConfirmation = false
        
        Logger.info("🚪 ProfileFlowView: Starting logout")
        
        Task {
            await authStateManager.logout()
            Logger.info("✅ ProfileFlowView: Logout completed")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Configuración")
                    .font(.title)
                
                Text("Próximamente...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Configuración")
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

// MARK: - Edit Profile View

struct EditProfileView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Editar Perfil")
                    .font(.title)
                
                Text("Próximamente...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
