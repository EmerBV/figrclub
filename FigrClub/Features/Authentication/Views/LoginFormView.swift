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
    @Environment(\.localizationManager) private var localizationManager
    
    // MARK: - Environment Objects
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    // MARK: - Body
    var body: some View {
        FigrVerticalScrollView {
            VStack(spacing: AppTheme.Spacing.xxLarge) {
                headerSection
                formSection
                actionButtonsSection
            }
            .padding(.horizontal, AppTheme.Padding.screenPadding)
            .padding(.top, AppTheme.Padding.xxxLarge)
            .padding(.bottom, AppTheme.Padding.xxLarge)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.xLarge) {
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
            Text(localizationManager.localizedString(for: .welcomeBack))
                .themedFont(.displayMedium)
                .themedTextColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(localizationManager.localizedString(for: .welcomeBackSubtitle))
                .themedFont(.bodyMedium)
                .themedTextColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.xLarge) {
            emailField
            passwordField
            forgotPasswordLink
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(localizationManager.localizedString(for: .email))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            TextField(localizationManager.localizedString(for: .emailPlaceholder), text: $viewModel.loginEmail)
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
            Text(localizationManager.localizedString(for: .password))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            SecureField(localizationManager.localizedString(for: .passwordPlaceholder), text: $viewModel.loginPassword)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.loginPasswordValidation) != .invalid
                ))
                .disabled(viewModel.isLoading)
        }
    }
    
    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button(localizationManager.localizedString(for: .forgotPassword)) {
                handleForgotPassword()
            }
            .themedFont(.bodySmall)
            .themedTextColor(.accent)
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.xLarge) {
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
                    Text(localizationManager.localizedString(for: .loggingIn))
                        .themedFont(.buttonMedium)
                } else {
                    Text(localizationManager.localizedString(for: .login))
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
            
            Text(localizationManager.localizedString(for: .or))
                .themedFont(.bodySmall)
                .themedTextColor(.secondary)
                .padding(.horizontal, AppTheme.Padding.large)
            
            Rectangle()
                .fill(themeManager.currentSecondaryTextColor.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, AppTheme.Padding.large)
    }
    
    private var createAccountButton: some View {
        Button(localizationManager.localizedString(for: .register)) {
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
