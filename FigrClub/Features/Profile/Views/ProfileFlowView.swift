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
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var isLoggingOut = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        FigrNavigationStack {
            FigrVerticalScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.bottom, AppTheme.Spacing.large)
                    optionsSection
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .alert(localizationManager.localizedString(for: .logout), isPresented: $showLogoutConfirmation) {
            Button(localizationManager.localizedString(for: .cancel), role: .cancel) {
                showLogoutConfirmation = false
            }
            Button(localizationManager.localizedString(for: .logout), role: .destructive) {
                performLogout()
            }
        } message: {
            Text(localizationManager.localizedString(for: .areYouSureToLogout))
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
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                // Imagen de perfil
                profileImageView
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    // Nombre y verificación
                    HStack(spacing: AppTheme.Spacing.xSmall) {
                        Text(user.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(Color.figrPrimary)
                        }
                    }
                    
                    // Rating con estrellas
                    HStack(spacing: AppTheme.Spacing.xxSmall) {
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
                    Text(localizationManager.localizedString(for: .inFigrClubSince, arguments: extractYear(from: user.createdAt)))
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
        .padding(.top, AppTheme.Spacing.xLarge)
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
            sectionHeader(localizationManager.localizedString(for: .contentString).uppercased())
            
            optionRow(
                icon: "square.grid.3x3.fill",
                title: localizationManager.localizedString(for: .myPostsString),
                action: { /* Navegar a mis posts */ }
            )
            
            optionRow(
                icon: "play.rectangle.fill",
                title: localizationManager.localizedString(for: .myReelsString),
                action: { /* Navegar a mis reels */ }
            )
            
            optionRow(
                icon: "dot.radiowaves.left.and.right",
                title: localizationManager.localizedString(for: .myLiveStreamsString),
                action: { /* Navegar a mis directos */ }
            )
            
            // Sección TRANSACCIONES
            sectionHeader(localizationManager.localizedString(for: .transactionsString).uppercased())
            
            optionRow(
                icon: "cart.fill",
                title: localizationManager.localizedString(for: .shoppingsString),
                action: { /* Navegar a compras */ }
            )
            
            optionRow(
                icon: "tag.fill",
                title: localizationManager.localizedString(for: .salesString),
                action: { /* Navegar a ventas */ }
            )
            
            /*
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
             */
            
            // Sección CUENTA
            sectionHeader(localizationManager.localizedString(for: .accountString).uppercased())
            
            /*
             optionRow(
             icon: "star.fill",
             title: "FigrClub PRO",
             action: { /* Navegar a PRO */ }
             )
             */
            
            optionRow(
                icon: "heart.fill",
                title: localizationManager.localizedString(for: .favoritesString),
                action: { /* Navegar a favoritos */ }
            )
            
            optionRow(
                icon: "gearshape.fill",
                title: localizationManager.localizedString(for: .settings),
                action: { navigationCoordinator.showSettings() }
            )
            
            /*
             // Sección FIGRCLUB AL HABLA
             sectionHeader("FIGRCLUB AL HABLA")
             
             optionRow(
             icon: "bubble.left.and.bubble.right.fill",
             title: "Chat de la comunidad",
             action: { /* Navegar a chat */ }
             )
             */
            
            // Botón de cerrar sesión
            logoutButton
                .padding(.bottom, AppTheme.Spacing.xLarge)
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
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.large)
        .padding(.bottom, AppTheme.Spacing.small)
    }
    
    // MARK: - Option Row
    private func optionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.medium) {
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
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            /*
            .background(
                Rectangle()
                    .fill(themeManager.currentBackgroundColor)
                    .contentShape(Rectangle())
            )
             */
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: AppTheme.Spacing.medium) {
                if isLoggingOut {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.figrRedAccent))
                        .scaleEffect(0.8)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                        .foregroundColor(Color.figrRedAccent)
                        .frame(width: 24, height: 24)
                }
                
                Text(isLoggingOut ? localizationManager.localizedString(for: .signingOut) : localizationManager.localizedString(for: .logout))
                    .font(.body)
                    .foregroundColor(Color.figrRedAccent)
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoggingOut)
        .padding(.top, AppTheme.Spacing.medium)
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
        FigrNavigationStack {
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
        FigrNavigationStack {
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
