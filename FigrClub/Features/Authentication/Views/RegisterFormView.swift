//
//  RegisterFormView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import SwiftUI

struct RegisterFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var errorHandler: ErrorHandler
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header Section
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
                Text("Crear cuenta en FigrClub")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Únete a nuestra comunidad")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Correo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("your@email.com", text: $viewModel.registerEmail)
                    .textFieldStyle(EBVTextFieldStyle(
                        isValid: getValidationState(viewModel.registerEmailValidation) != .invalid
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(viewModel.isLoading)
            }
            
            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre de usuario")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("nombreusuario", text: $viewModel.registerUsername)
                    .textFieldStyle(EBVTextFieldStyle(
                        isValid: getValidationState(viewModel.usernameValidation) != .invalid
                    ))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(viewModel.isLoading)
            }
            
            // Full Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre completo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("Tu nombre completo", text: $viewModel.registerFullName)
                    .textFieldStyle(EBVTextFieldStyle(
                        isValid: getValidationState(viewModel.fullNameValidation) != .invalid
                    ))
                    .autocapitalization(.words)
                    .disabled(viewModel.isLoading)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                SecureField("Crea una contraseña", text: $viewModel.registerPassword)
                    .textFieldStyle(EBVTextFieldStyle(
                        isValid: getValidationState(viewModel.registerPasswordValidation) != .invalid
                    ))
                    .disabled(viewModel.isLoading)
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirmar contraseña")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                SecureField("Confirma tu contraseña", text: $viewModel.registerConfirmPassword)
                    .textFieldStyle(EBVTextFieldStyle(
                        isValid: getValidationState(viewModel.confirmPasswordValidation) != .invalid
                    ))
                    .disabled(viewModel.isLoading)
            }
            
            // Terms and Conditions
            termsAndConditionsView
        }
    }
    
    private var termsAndConditionsView: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                viewModel.acceptTerms.toggle()
            } label: {
                Image(systemName: viewModel.acceptTerms ? "checkmark.circle.fill" : "circle")
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
                    } else {
                        Text("Crear Cuenta")
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
            Button("¿Ya tienes cuenta? Inicia sesión") {
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
    
    private func handleTermsTapped() {
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
