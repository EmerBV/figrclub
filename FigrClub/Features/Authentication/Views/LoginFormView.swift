//
//  LoginFormView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import SwiftUI

struct LoginFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var errorHandler: ErrorHandler
    
    @EnvironmentObject private var featureFlagManager: FeatureFlagManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header Section
                /*
                 if featureFlagManager.isFeatureEnabledSync(.appLogo) {
                 headerSection
                 }
                 */
                
                headerSection
                
                // Form Section
                formSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Logo
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .frame(width: 80, height: 80)
                )
            
            // Welcome Title
            VStack(spacing: 8) {
                Text("Bienvenido a FigrClub")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Inicia sesión en tu cuenta")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 24) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Correo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("your@email.com", text: $viewModel.loginEmail)
                    .textFieldStyle(EBVTextFieldStyle(
                        isValid: getValidationState(viewModel.loginEmailValidation) != .invalid
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(viewModel.isLoading)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                SecureField("Tu contraseña", text: $viewModel.loginPassword)
                    .textFieldStyle(EBVTextFieldStyle(
                        isValid: getValidationState(viewModel.loginPasswordValidation) != .invalid
                    ))
                    .disabled(viewModel.isLoading)
            }
            
            // Forgot Password Link
            HStack {
                Spacer()
                Button("¿Olvidaste tu contraseña?") {
                    handleForgotPassword()
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.blue)
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Login Button
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
                    } else {
                        Text("Iniciar Sesión")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(EBVAuthBtnStyle(
                isEnabled: viewModel.canLogin && !viewModel.isLoading,
                isLoading: viewModel.isLoading
            ))
            .disabled(!viewModel.canLogin || viewModel.isLoading)
            
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
            
            // Create Account Button
            Button("Crear una cuenta") {
                Logger.info("🔄 LoginFormView: User tapped 'Crear una cuenta'")
                viewModel.switchToRegister()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .disabled(viewModel.isLoading)
        }
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
