//
//  LoginView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = DependencyContainer.shared.makeLoginViewModel()
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var showRegister = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.xxxLarge) {
                    // Header
                    VStack(spacing: Spacing.large) {
                        // Logo
                        Image("FigrClubLogo") // Add your logo to assets
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                            .padding(.top, Spacing.xxxLarge)
                        
                        // Welcome Text
                        VStack(spacing: Spacing.small) {
                            Text("¡Bienvenido!")
                                .font(.figrTitle)
                                .foregroundColor(.figrTextPrimary)
                            
                            Text("Inicia sesión para continuar")
                                .font(.figrBody)
                                .foregroundColor(.figrTextSecondary)
                        }
                    }
                    
                    // Login Form
                    VStack(spacing: Spacing.xLarge) {
                        VStack(spacing: Spacing.large) {
                            // Email Field
                            FigrTextField(
                                title: "Email",
                                placeholder: "tu@email.com",
                                text: $viewModel.email,
                                validation: viewModel.emailValidationState,
                                leadingIcon: "envelope"
                            )
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            
                            // Password Field
                            FigrTextField(
                                title: "Contraseña",
                                placeholder: "Tu contraseña",
                                text: $viewModel.password,
                                isSecure: true,
                                validation: viewModel.passwordValidationState,
                                leadingIcon: "lock"
                            )
                            .textContentType(.password)
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("¿Olvidaste tu contraseña?") {
                                viewModel.forgotPassword()
                            }
                            .font(.figrFootnote)
                            .foregroundColor(.figrPrimary)
                        }
                        
                        // Login Button
                        FigrButton(
                            title: "Iniciar Sesión",
                            isLoading: viewModel.isLoading,
                            isEnabled: viewModel.isFormValid && !viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.login()
                            }
                        }
                        .hapticFeedback()
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.figrBorder)
                            
                            Text("o")
                                .font(.figrFootnote)
                                .foregroundColor(.figrTextSecondary)
                                .padding(.horizontal, Spacing.medium)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.figrBorder)
                        }
                        
                        // Social Login Buttons
                        VStack(spacing: Spacing.medium) {
                            SocialLoginButton(
                                title: "Continuar con Apple",
                                iconName: "apple.logo",
                                backgroundColor: .black,
                                foregroundColor: .white
                            ) {
                                // Handle Apple Sign In
                            }
                            
                            SocialLoginButton(
                                title: "Continuar con Google",
                                iconName: "globe",
                                backgroundColor: .white,
                                foregroundColor: .black
                            ) {
                                // Handle Google Sign In
                            }
                        }
                    }
                    
                    Spacer(minLength: Spacing.large)
                    
                    // Register Link
                    VStack(spacing: Spacing.medium) {
                        HStack {
                            Text("¿No tienes cuenta?")
                                .font(.figrBody)
                                .foregroundColor(.figrTextSecondary)
                            
                            Button("Regístrate") {
                                showRegister = true
                            }
                            .font(.figrBody.weight(.medium))
                            .foregroundColor(.figrPrimary)
                        }
                        
                        // Terms and Privacy
                        Text("Al continuar, aceptas nuestros [Términos de Servicio](https://figrclub.com/terms) y [Política de Privacidad](https://figrclub.com/privacy)")
                            .font(.figrCaption)
                            .foregroundColor(.figrTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.large)
                    }
                }
                .padding(.horizontal, Spacing.xLarge)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(.figrBackground)
        .dismissKeyboardOnTap()
        .toast(isPresented: $viewModel.showError) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.figrError)
                
                Text(viewModel.errorMessage ?? "Error desconocido")
                    .font(.figrCallout)
                    .foregroundColor(.figrTextPrimary)
            }
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "LoginView")
        }
        .animation(.easeInOut, value: keyboardObserver.isKeyboardVisible)
    }
}

// MARK: - Social Login Button
struct SocialLoginButton: View {
    let title: String
    let iconName: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: iconName)
                    .font(.figrBody)
                
                Text(title)
                    .font(.figrCallout.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(.figrBorder, lineWidth: 1)
            )
        }
    }
}
