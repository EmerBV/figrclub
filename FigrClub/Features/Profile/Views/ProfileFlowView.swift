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
            ScrollView {
                VStack(spacing: Spacing.large) {
                    headerSection
                    userInfoSection
                    profileActionsSection
                }
                .padding()
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
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
        .sheet(isPresented: $navigationCoordinator.showingEditProfile) {
            EditProfileView(user: user)
        }
        .onReceive(authStateManager.$authState) { authState in
            if case .unauthenticated = authState {
                isLoggingOut = false
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Spacing.medium) {
            // Imagen de perfil usando KFImage y las extensiones existentes
            let imageURL = URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(user.id)/profile")
            
            if user.hasProfileImage {
                
                /*
                OptimizedKFImage.highQuality(url: imageURL) {
                    ShimmerImagePlaceholder()
                }
                 */
                
                KFImage(imageURL)
                    .profileImageStyle(size: 100)
                    .overlay(
                        // Badge de verificación superpuesto
                        user.isVerified ?
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 35, y: -35)
                        : nil
                    )
            } else {
                // Placeholder para usuarios sin imagen de perfil
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .overlay(
                        // Badge de verificación superpuesto
                        user.isVerified ?
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 35, y: -35)
                        : nil
                    )
            }
            
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
            
            HStack(spacing: Spacing.xLarge) {
                statView(title: "Posts", count: user.postsCount)
                statView(title: "Siguiendo", count: user.followingCount)
                statView(title: "Seguidores", count: user.followersCount)
            }
            .padding(.top, Spacing.medium)
        }
    }
    
    private var profileActionsSection: some View {
        VStack(spacing: Spacing.medium) {
            Button("Editar Perfil") {
                navigationCoordinator.showEditProfile()
            }
            .buttonStyle(EBVPrimaryBtnStyle(isEnabled: true))
            
            Button("Configuración") {
                navigationCoordinator.showSettings()
            }
            .buttonStyle(EBVPrimaryBtnStyle(isEnabled: true))
            
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
        .padding(.top, Spacing.large)
    }
    
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
