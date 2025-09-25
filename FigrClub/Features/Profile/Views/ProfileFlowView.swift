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
                        .padding(.horizontal, AppTheme.Padding.large)
                        .padding(.bottom, AppTheme.Padding.large)
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
        
        /*
        .sheet(isPresented: $navigationCoordinator.showingSettings) {
            SettingsView(user: user)
        }
         */
        
        /*
        .fullScreenCover(isPresented: $navigationCoordinator.showingSettings) {
            SettingsView(user: user)
                .environmentObject(themeManager)
                .environment(\.localizationManager, localizationManager)
        }
         */
        
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
                            .themedTextColor(.primary)
                        
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
                            .themedTextColor(.secondary)
                    }
                    
                    // Fecha de registro
                    Text(localizationManager.localizedString(for: .inFigrClubSince, arguments: extractYear(from: user.createdAt)))
                        .font(.caption)
                        .themedTextColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination: UserProfileDetailView(user: user)) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .themedTextColor(.secondary)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(.top, AppTheme.Padding.xLarge)
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
    
    // MARK: - Header Section
    private func headerSection(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.medium))
                .themedTextColor(.secondary)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.top, AppTheme.Padding.large)
        .padding(.bottom, AppTheme.Padding.small)
    }
    
    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(spacing: 0) {
            // Sección CONTENIDO
            headerSection(localizationManager.localizedString(for: .contentString).uppercased())
            
            ProfileOptionRow(
                icon: "square.grid.3x3.fill",
                title: localizationManager.localizedString(for: .myPostsString),
                action: { /* Navegar a mis posts */ }
            )
            
            ProfileOptionRow(
                icon: "play.rectangle.fill",
                title: localizationManager.localizedString(for: .myReelsString),
                action: { /* Navegar a mis reels */ }
            )
            
            ProfileOptionRow(
                icon: "dot.radiowaves.left.and.right",
                title: localizationManager.localizedString(for: .myLiveStreamsString),
                action: { /* Navegar a mis directos */ }
            )
            
            // Sección TRANSACCIONES
            headerSection(localizationManager.localizedString(for: .transactionsString).uppercased())
            
            ProfileOptionRow(
                icon: "cart.fill",
                title: localizationManager.localizedString(for: .shoppingsString),
                action: { /* Navegar a compras */ }
            )
            
            ProfileOptionRow(
                icon: "tag.fill",
                title: localizationManager.localizedString(for: .salesString),
                action: { /* Navegar a ventas */ }
            )
            
            /*
             ProfileOptionRow(
             icon: "creditcard.fill",
             title: "Monedero",
             action: { /* Navegar a monedero */ }
             )
             
             ProfileOptionRow(
             icon: "leaf.fill",
             title: "Tu impacto positivo",
             action: { /* Navegar a impacto */ }
             )
             */
            
            // Sección CUENTA
            headerSection(localizationManager.localizedString(for: .accountString).uppercased())
            
            /*
             ProfileOptionRow(
             icon: "star.fill",
             title: "FigrClub PRO",
             action: { /* Navegar a PRO */ }
             )
             */
            
            ProfileOptionRow(
                icon: "heart.fill",
                title: localizationManager.localizedString(for: .favoritesString),
                action: { /* Navegar a favoritos */ }
            )
            
            // Usando NavigationLink para la navegación sin que salga el modal
            ProfileOptionRow(
                icon: "gearshape.fill",
                title: localizationManager.localizedString(for: .settings),
                destination: SettingsView(user: user)
            )
            
            // Ejemplo usando action (comentado el anterior para mostrar ambas opciones)
            /*
            ProfileOptionRow(
                icon: "gearshape.fill",
                title: localizationManager.localizedString(for: .settings),
                action: { navigationCoordinator.showSettings() }
            )
            */
            
            /*
             // Sección FIGRCLUB AL HABLA
             headerSection("FIGRCLUB AL HABLA")
             
             ProfileOptionRow(
             icon: "bubble.left.and.bubble.right.fill",
             title: "Chat de la comunidad",
             action: { /* Navegar a chat */ }
             )
             */
            
            // Botón de cerrar sesión
            logoutButton
                .padding(.bottom, AppTheme.Padding.xLarge)
        }
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
            .padding(.horizontal, AppTheme.Padding.large)
            .padding(.vertical, AppTheme.Padding.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoggingOut)
        .padding(.top, AppTheme.Padding.medium)
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
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        FigrNavigationStack {
            FigrVerticalScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 60))
                            .themedTextColor(.secondary)
                        
                        Text(localizationManager.localizedString(for: .settings))
                            .font(.title.weight(.bold))
                            .themedTextColor(.primary)
                        
                        Text("Próximamente...")
                            .font(.body)
                            .themedTextColor(.secondary)
                    }
                    .padding(.top, AppTheme.Padding.xLarge)
                    
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Padding.large)
            }
            .navigationTitle(localizationManager.localizedString(for: .settings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                /*
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            //.font(.title2)
                            .themedTextColor(.primary)
                    }
                }
                 */
                
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button {
                         dismiss()
                     } label: {
                         Image(systemName: "arrow.left")
                             .font(.title2)
                             .themedTextColor(.primary)
                     }
                 }
            }
            .navigationBarBackButtonHidden()
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
                    .themedTextColor(.secondary)
                
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
