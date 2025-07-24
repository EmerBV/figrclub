//
//  RegisterFormView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import SwiftUI

struct RegisterFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var errorHandler: GlobalErrorHandler
    @Environment(\.localizationManager) private var localizationManager
    
    // MARK: - Environment Objects
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Legal Documents State
    @State private var showingTermsOfService = false
    @State private var showingPrivacyPolicy = false
    
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
        .sheet(isPresented: $showingTermsOfService) {
            LegalDocumentView.termsOfService(errorHandler: errorHandler)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            LegalDocumentView.privacyPolicy(errorHandler: errorHandler)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            logoSection
            welcomeSection
        }
    }
    
    // MARK: - Logo Section
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
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text(localizationManager.localizedString(for: .registerTitle))
                .themedFont(.displaySmall)
                .themedTextColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(localizationManager.localizedString(for: .joinCommunity))
                .themedFont(.bodyMedium)
                .themedTextColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            emailField
            usernameField
            fullnameField
            passwordField
            confirmPasswordField
            termsAndConditionsView
            consentsSection
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(localizationManager.localizedString(for: .email))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            TextField(localizationManager.localizedString(for: .email), text: $viewModel.registerEmail)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.registerEmailValidation) != .invalid
                ))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(viewModel.isLoading)
        }
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(localizationManager.localizedString(for: .username))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            TextField(localizationManager.localizedString(for: .usernamePlaceholder), text: $viewModel.registerUsername)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.usernameValidation) != .invalid
                ))
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(viewModel.isLoading)
        }
    }
    
    private var fullnameField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(localizationManager.localizedString(for: .fullName))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            TextField(localizationManager.localizedString(for: .fullNamePlaceholder), text: $viewModel.registerFullName)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.fullNameValidation) != .invalid
                ))
                .autocapitalization(.words)
                .disabled(viewModel.isLoading)
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(localizationManager.localizedString(for: .password))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            SecureField(localizationManager.localizedString(for: .passwordPlaceholder), text: $viewModel.registerPassword)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.registerPasswordValidation) != .invalid
                ))
                .disabled(viewModel.isLoading)
            
            // Password requirements info
            if !viewModel.registerPassword.isEmpty {
                passwordRequirementsView
            }
        }
    }
    
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(localizationManager.localizedString(for: .confirmPassword))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            SecureField(localizationManager.localizedString(for: .confirmPasswordPlaceholder), text: $viewModel.registerConfirmPassword)
                .modifier(ThemedTextFieldModifier(
                    isValid: getValidationState(viewModel.confirmPasswordValidation) != .invalid
                ))
                .disabled(viewModel.isLoading)
        }
    }
    
    private var termsAndConditionsView: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                if !viewModel.acceptTerms {
                    viewModel.acceptTermsAndConditions()
                } else {
                    viewModel.acceptTerms = false
                    viewModel.termsAcceptedAt = nil
                }
            } label: {
                Image(systemName: viewModel.acceptTerms ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(viewModel.acceptTerms ? .blue : .gray)
            }
            .disabled(viewModel.isLoading)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text("Acepto los ")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingTermsOfService = true
                    }) {
                        Text(localizationManager.localizedString(for: .termsAndConditions))
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .underline()
                    }
                    
                    Text(" y la ")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        Text(localizationManager.localizedString(for: .privacyPolicy))
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                
                if let acceptedAt = viewModel.termsAcceptedAt {
                    Text(localizationManager.localizedString(for: .acceptedAt, arguments: DateFormatter.localizedString(from: acceptedAt, dateStyle: .short, timeStyle: .short)))
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .padding(.top, 2)
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Register Button
            Button {
                Task {
                    await performRegister()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text(localizationManager.localizedString(for: .creatingAccount))
                    } else {
                        Text(localizationManager.localizedString(for: .createAccount))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(EBVAuthBtnStyle(
                isEnabled: viewModel.canRegister && !viewModel.isLoading,
                isLoading: viewModel.isLoading
            ))
            .disabled(!viewModel.canRegister || viewModel.isLoading)
            
            // Divider with "o"
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                Text("o")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Login Button
            Button(localizationManager.localizedString(for: .alreadyHaveAccount)) {
                Logger.info("🔄 RegisterFormView: User tapped 'Ya tienes cuenta'")
                viewModel.switchToLogin()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .disabled(viewModel.isLoading)
        }
    }
    
    private func performRegister() async {
        errorHandler.dismiss()
        
        if let error = await viewModel.registerWithErrorHandling() {
            errorHandler.handle(error)
        }
    }
    
    
    
    private func getValidationState(_ validation: ValidationResult) -> ValidationState {
        switch validation {
        case .valid:
            return .valid
        case .invalid:
            return .invalid
        }
    }
    
    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: passwordMeetsLength ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordMeetsLength ? .green : .gray)
                    .font(.system(size: 12))
                Text(localizationManager.localizedString(for: .passwordMinLength))
                    .font(.system(size: 12))
                    .foregroundColor(passwordMeetsLength ? .green : .gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: passwordHasLetter ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordHasLetter ? .green : .gray)
                    .font(.system(size: 12))
                Text(localizationManager.localizedString(for: .passwordMustHaveLetter))
                    .font(.system(size: 12))
                    .foregroundColor(passwordHasLetter ? .green : .gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: passwordHasNumber ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordHasNumber ? .green : .gray)
                    .font(.system(size: 12))
                Text(localizationManager.localizedString(for: .passwordMustHaveNumber))
                    .font(.system(size: 12))
                    .foregroundColor(passwordHasNumber ? .green : .gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: passwordHasSpecialChar ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordHasSpecialChar ? .green : .gray)
                    .font(.system(size: 12))
                Text(localizationManager.localizedString(for: .passwordMustHaveSpecial))
                    .font(.system(size: 12))
                    .foregroundColor(passwordHasSpecialChar ? .green : .gray)
            }
        }
        .padding(.top, 4)
    }
    
    // Password validation computed properties
    private var passwordMeetsLength: Bool {
        viewModel.registerPassword.count >= 8
    }
    
    private var passwordHasLetter: Bool {
        viewModel.registerPassword.rangeOfCharacter(from: .letters) != nil
    }
    
    private var passwordHasNumber: Bool {
        viewModel.registerPassword.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    private var passwordHasSpecialChar: Bool {
        viewModel.registerPassword.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
    }
    
    private var consentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: .consents))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            // Data Processing Consent
            consentView(
                title: localizationManager.localizedString(for: .dataProcessing),
                description: localizationManager.localizedString(for: .dataProcessingDescription),
                isAccepted: viewModel.acceptDataProcessing,
                acceptedAt: viewModel.dataProcessingAcceptedAt,
                onToggle: {
                    if !viewModel.acceptDataProcessing {
                        viewModel.acceptDataProcessingConsent()
                    } else {
                        viewModel.acceptDataProcessing = false
                        viewModel.dataProcessingAcceptedAt = nil
                    }
                }
            )
            
            // Functional Cookies Consent
            consentView(
                title: localizationManager.localizedString(for: .functionalCookies),
                description: localizationManager.localizedString(for: .functionalCookiesDescription),
                isAccepted: viewModel.acceptFunctionalCookies,
                acceptedAt: viewModel.functionalCookiesAcceptedAt,
                onToggle: {
                    if !viewModel.acceptFunctionalCookies {
                        viewModel.acceptFunctionalCookiesConsent()
                    } else {
                        viewModel.acceptFunctionalCookies = false
                        viewModel.functionalCookiesAcceptedAt = nil
                    }
                }
            )
        }
    }
    
    private func consentView(
        title: String,
        description: String,
        isAccepted: Bool,
        acceptedAt: Date?,
        onToggle: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: isAccepted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isAccepted ? .green : .gray)
            }
            .disabled(viewModel.isLoading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let acceptedAt = acceptedAt {
                    Text(localizationManager.localizedString(for: .acceptedAt, arguments: DateFormatter.localizedString(from: acceptedAt, dateStyle: .short, timeStyle: .short)))
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
        }
    }
}
