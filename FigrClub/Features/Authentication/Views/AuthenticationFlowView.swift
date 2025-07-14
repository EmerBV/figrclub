//
//  AuthenticationFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import SwiftUI

struct AuthenticationFlowView: View {
    @State private var authViewModel: AuthViewModel?
    @StateObject private var errorHandler = ErrorHandler()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        headerView
                        
                        // Content
                        if let viewModel = authViewModel {
                            // Tab selector
                            tabSelectorView(viewModel: viewModel)
                            
                            // Form content
                            formContentView(viewModel: viewModel)
                        } else {
                            // Loading state
                            AuthLoadingView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
        .errorAlert(errorHandler: errorHandler) {
            await retryAuthAction()
        }
    }
    
    // MARK: - Private Views
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.blue)
            
            Text("FigrClub")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(authViewModel?.isShowingLogin == true ? "Bienvenido de vuelta" : "Únete a la comunidad")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    private func tabSelectorView(viewModel: AuthViewModel) -> some View {
        HStack(spacing: 0) {
            AuthTabButton(
                title: "Iniciar Sesión",
                isSelected: viewModel.isShowingLogin
            ) {
                viewModel.switchToLogin()
                errorHandler.dismiss()
            }
            
            AuthTabButton(
                title: "Registrarse",
                isSelected: !viewModel.isShowingLogin
            ) {
                viewModel.switchToRegister()
                errorHandler.dismiss()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                .stroke(Color.blue, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    private func formContentView(viewModel: AuthViewModel) -> some View {
        Group {
            if viewModel.isShowingLogin {
                LoginFormView(viewModel: viewModel, errorHandler: errorHandler)
            } else {
                RegisterFormView(viewModel: viewModel, errorHandler: errorHandler)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupViewModel() {
        if authViewModel == nil {
            authViewModel = DependencyInjector.shared.resolve(AuthViewModel.self)
        }
    }
    
    private func retryAuthAction() async {
        guard let viewModel = authViewModel else { return }
        
        if viewModel.isShowingLogin {
            if let error = await viewModel.loginWithErrorHandling() {
                errorHandler.handle(error)
            }
        } else {
            if let error = await viewModel.registerWithErrorHandling() {
                errorHandler.handle(error)
            }
        }
    }
}

// MARK: - Supporting Form Views
struct LoginFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var errorHandler: ErrorHandler
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            AuthTextField(
                text: $viewModel.loginEmail,
                placeholder: "tu@email.com",
                keyboardType: .emailAddress,
                validationState: getValidationState(viewModel.loginEmailValidation)
            )
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .disabled(viewModel.isLoading)
            
            // Password Field
            AuthSecureField(
                text: $viewModel.loginPassword,
                placeholder: "Tu contraseña",
                validationState: getValidationState(viewModel.loginPasswordValidation)
            )
            .disabled(viewModel.isLoading)
            
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
            }
            .buttonStyle(FigrButtonStyle(
                isEnabled: viewModel.canLogin && !viewModel.isLoading,
                isLoading: viewModel.isLoading
            ))
            .disabled(!viewModel.canLogin || viewModel.isLoading)
            
            // Forgot Password
            Button("¿Olvidaste tu contraseña?") {
                handleForgotPassword()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            .disabled(viewModel.isLoading)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Private Methods
    
    private func performLogin() async {
        errorHandler.dismiss()
        
        if let error = await viewModel.loginWithErrorHandling() {
            errorHandler.handle(error)
        }
    }
    
    private func handleForgotPassword() {
        // TODO: Implement password recovery
        Logger.info("🔗 Forgot password tapped")
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

struct RegisterFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var errorHandler: ErrorHandler
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            AuthTextField(
                text: $viewModel.registerEmail,
                placeholder: "tu@email.com",
                keyboardType: .emailAddress,
                validationState: getValidationState(viewModel.registerEmailValidation)
            )
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .disabled(viewModel.isLoading)
            
            // Username Field
            AuthTextField(
                text: $viewModel.registerUsername,
                placeholder: "nombreusuario",
                validationState: getValidationState(viewModel.usernameValidation)
            )
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .disabled(viewModel.isLoading)
            
            // Full Name Field
            AuthTextField(
                text: $viewModel.registerFullName,
                placeholder: "Tu nombre completo",
                validationState: getValidationState(viewModel.fullNameValidation)
            )
            .autocapitalization(.words)
            .disabled(viewModel.isLoading)
            
            // Password Field
            AuthSecureField(
                text: $viewModel.registerPassword,
                placeholder: "Tu contraseña",
                validationState: getValidationState(viewModel.registerPasswordValidation)
            )
            .disabled(viewModel.isLoading)
            
            // Confirm Password Field
            AuthSecureField(
                text: $viewModel.registerConfirmPassword,
                placeholder: "Confirma tu contraseña",
                validationState: getValidationState(viewModel.confirmPasswordValidation)
            )
            .disabled(viewModel.isLoading)
            
            // Terms and Conditions
            termsAndConditionsView
            
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
                    } else {
                        Text("Crear Cuenta")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .buttonStyle(FigrButtonStyle(
                isEnabled: viewModel.canRegister && !viewModel.isLoading,
                isLoading: viewModel.isLoading
            ))
            .disabled(!viewModel.canRegister || viewModel.isLoading)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Private Views
    
    private var termsAndConditionsView: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                viewModel.acceptTerms.toggle()
            } label: {
                Image(systemName: viewModel.acceptTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(viewModel.acceptTerms ? .blue : .gray)
            }
            .disabled(viewModel.isLoading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Acepto los ")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                +
                Text("términos y condiciones")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .underline()
                +
                Text(" y la ")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                +
                Text("política de privacidad")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .underline()
            }
            .multilineTextAlignment(.leading)
            .onTapGesture {
                handleTermsTapped()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performRegister() async {
        errorHandler.dismiss()
        
        if let error = await viewModel.registerWithErrorHandling() {
            errorHandler.handle(error)
        }
    }
    
    private func handleTermsTapped() {
        // TODO: Show terms and conditions
        Logger.info("🔗 Terms and conditions tapped")
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

struct AuthLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            Text("Preparando autenticación...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview
#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
            .environmentObject(DependencyInjector.shared.resolve(AuthStateManager.self))
    }
}
#endif


