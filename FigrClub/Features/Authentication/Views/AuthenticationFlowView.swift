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
                                    errorHandler.dismiss() // ← Limpiar errores al cambiar tab
                                }
                                
                                AuthTabButton(
                                    title: "Registrarse",
                                    isSelected: !viewModel.isShowingLogin
                                ) {
                                    viewModel.switchToRegister()
                                    errorHandler.dismiss() // ← Limpiar errores al cambiar tab
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                            
                            // Form Content
                            if viewModel.isShowingLogin {
                                LoginFormView(viewModel: viewModel, errorHandler: errorHandler)
                            } else {
                                RegisterFormView(viewModel: viewModel, errorHandler: errorHandler)
                            }
                        } else {
                            // Loading state while creating ViewModel
                            AuthLoadingView()
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
        .errorAlert(errorHandler: errorHandler) { // ← Error handler con retry específico para auth
            // Retry action específica para auth - usando métodos limpios
            if let viewModel = authViewModel {
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
                // TODO: Implementar recuperación de contraseña
                Logger.info("🔗 Forgot password tapped")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            .disabled(viewModel.isLoading)
        }
        .padding(.top, 20)
    }
    
    private func performLogin() async {
        // Limpiar errores previos
        errorHandler.dismiss()
        
        // Usar el método público del ViewModel que retorna error
        if let error = await viewModel.loginWithErrorHandling() {
            errorHandler.handle(error)
        }
        // Si no hay error, el login fue exitoso y AuthStateManager maneja la navegación
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
            HStack(alignment: .top, spacing: 12) {
                Button {
                    viewModel.acceptTerms.toggle()
                } label: {
                    Image(systemName: viewModel.acceptTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.acceptTerms ? .blue : .gray)
                }
                .disabled(viewModel.isLoading)
                
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
            .buttonStyle(FigrButtonStyle(
                isEnabled: viewModel.canRegister && !viewModel.isLoading,
                isLoading: viewModel.isLoading
            ))
            .disabled(!viewModel.canRegister || viewModel.isLoading)
        }
        .padding(.top, 20)
    }
    
    private func performRegister() async {
        // Limpiar errores previos
        errorHandler.dismiss()
        
        // Usar el método público del ViewModel que retorna error
        if let error = await viewModel.registerWithErrorHandling() {
            errorHandler.handle(error)
        }
        // Si no hay error, el registro fue exitoso y AuthStateManager maneja la navegación
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


