//
//  AuthenticationFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import SwiftUI

struct AuthenticationFlowView: View {
    @State private var authViewModel: AuthViewModel?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
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
                        
                        // Solo mostrar contenido si tenemos authViewModel
                        if let viewModel = authViewModel {
                            // Toggle between Login/Register
                            HStack(spacing: 0) {
                                AuthTabButton(
                                    title: "Iniciar Sesión",
                                    isSelected: viewModel.isShowingLogin
                                ) {
                                    viewModel.switchToLogin()
                                }
                                
                                AuthTabButton(
                                    title: "Registrarse",
                                    isSelected: !viewModel.isShowingLogin
                                ) {
                                    viewModel.switchToRegister()
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                            
                            // Form Content
                            if viewModel.isShowingLogin {
                                LoginFormView(viewModel: viewModel)
                            } else {
                                RegisterFormView(viewModel: viewModel)
                            }
                        } else {
                            // Loading state while creating ViewModel
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            // Resolver AuthViewModel cuando la vista aparece
            if authViewModel == nil {
                authViewModel = DependencyInjector.shared.resolve(AuthViewModel.self)
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { authViewModel?.showError == true },
            set: { _ in authViewModel?.hideError() }
        )) {
            Button("OK") {
                authViewModel?.hideError()
            }
        } message: {
            Text(authViewModel?.errorMessage ?? "Ha ocurrido un error")
        }
    }
}

// MARK: - Supporting Form Views
struct LoginFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    
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
            
            // Password Field
            AuthSecureField(
                text: $viewModel.loginPassword,
                placeholder: "Tu contraseña",
                validationState: getValidationState(viewModel.loginPasswordValidation)
            )
            
            // Login Button
            Button {
                Task {
                    await viewModel.login()
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
            .buttonStyle(FigrButtonStyle(isEnabled: viewModel.canLogin, isLoading: viewModel.isLoading))
            .disabled(!viewModel.canLogin)
            
            // Forgot Password
            Button("¿Olvidaste tu contraseña?") {
                // TODO: Implementar recuperación de contraseña
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
        }
        .padding(.top, 20)
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
            
            // Username Field
            AuthTextField(
                text: $viewModel.registerUsername,
                placeholder: "nombreusuario",
                validationState: getValidationState(viewModel.usernameValidation)
            )
            .autocapitalization(.none)
            .autocorrectionDisabled()
            
            // Full Name Field
            AuthTextField(
                text: $viewModel.registerFullName,
                placeholder: "Tu nombre completo",
                validationState: getValidationState(viewModel.fullNameValidation)
            )
            .autocapitalization(.words)
            
            // Password Field
            AuthSecureField(
                text: $viewModel.registerPassword,
                placeholder: "Tu contraseña",
                validationState: getValidationState(viewModel.registerPasswordValidation)
            )
            
            // Confirm Password Field
            AuthSecureField(
                text: $viewModel.registerConfirmPassword,
                placeholder: "Confirma tu contraseña",
                validationState: getValidationState(viewModel.confirmPasswordValidation)
            )
            
            // Terms and Conditions
            HStack(alignment: .top, spacing: 12) {
                Button {
                    viewModel.acceptTerms.toggle()
                } label: {
                    Image(systemName: viewModel.acceptTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.acceptTerms ? .blue : .gray)
                }
                
                Text("Acepto los términos y condiciones y la política de privacidad")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Register Button
            Button {
                Task {
                    await viewModel.register()
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
            .buttonStyle(FigrButtonStyle(isEnabled: viewModel.canRegister, isLoading: viewModel.isLoading))
            .disabled(!viewModel.canRegister)
        }
        .padding(.top, 20)
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

// MARK: - Preview
#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
            .environmentObject(DependencyInjector.shared.resolve(AuthStateManager.self))
    }
}
#endif


