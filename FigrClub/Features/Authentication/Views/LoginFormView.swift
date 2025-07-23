//
//  LoginFormView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import SwiftUI

struct LoginFormView: View {
    // MARK: - Dependencies
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var errorHandler: GlobalErrorHandler
    
    // MARK: - Environment Objects
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xlarge) {
                headerSection
                formSection
                actionButtonsSection
            }
            .padding(.horizontal, AppTheme.Spacing.screenPadding)
            .padding(.top, AppTheme.Spacing.xxlarge)
            .padding(.bottom, AppTheme.Spacing.xlarge)
        }
        .themedBackground()
        .onAppear {
            Logger.info("🎨 LoginFormView: Applied themed styling")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            logoSection
            welcomeSection
        }
    }
    
    private var logoSection: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(width: AppTheme.IconSize.xxlarge, height: AppTheme.IconSize.xxlarge)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.clear)
                    .frame(width: AppTheme.IconSize.xxlarge, height: AppTheme.IconSize.xxlarge)
            )
    }
    
    private var welcomeSection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text("Bienvenido a FigrClub")
                .themedFont(.displayMedium)
                .themedTextColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Inicia sesión en tu cuenta")
                .themedFont(.bodyMedium)
                .themedTextColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            emailField
            passwordField
            forgotPasswordLink
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Correo")
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            TextField("your@email.com", text: $viewModel.loginEmail)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.loginEmailValidation) != .invalid
                ))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(viewModel.isLoading)
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Contraseña")
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            SecureField("Tu contraseña", text: $viewModel.loginPassword)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.loginPasswordValidation) != .invalid
                ))
                .disabled(viewModel.isLoading)
        }
    }
    
    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button("¿Olvidaste tu contraseña?") {
                handleForgotPassword()
            }
            .themedFont(.bodySmall)
            .themedTextColor(.accent)
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            loginButton
            dividerSection
            createAccountButton
        }
    }
    
    private var loginButton: some View {
        Button {
            Task {
                await performLogin()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Iniciando sesión...")
                        .themedFont(.buttonMedium)
                } else {
                    Text("Iniciar Sesión")
                        .themedFont(.buttonMedium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .modifier(FigrPrimaryButtonModifier(
            isEnabled: viewModel.canLogin && !viewModel.isLoading
        ))
        .disabled(!viewModel.canLogin || viewModel.isLoading)
    }
    
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(themeManager.currentSecondaryTextColor.opacity(0.3))
                .frame(height: 1)
            
            Text("o")
                .themedFont(.bodySmall)
                .themedTextColor(.secondary)
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            Rectangle()
                .fill(themeManager.currentSecondaryTextColor.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    private var createAccountButton: some View {
        Button("Crear una cuenta") {
            Logger.info("🔄 LoginFormView: User tapped 'Crear una cuenta'")
            viewModel.switchToRegister()
        }
        .themedFont(.buttonMedium)
        .themedTextColor(.primary)
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Private Methods
    
    private func performLogin() async {
        errorHandler.dismiss()
        
        if let error = await viewModel.loginWithErrorHandling() {
            errorHandler.handle(error)
        }
    }
    
    private func handleForgotPassword() {
        Logger.info("🔗 Forgot password tapped")
        // TODO: Implement password recovery
    }
    
    private func getValidationState(_ validation: ValidationResult) -> ValidationState {
        switch validation {
        case .valid:
            return .valid
        case .invalid:
            return .invalid
        }
    }
}
