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
                
                // Password requirements info
                if !viewModel.registerPassword.isEmpty {
                    passwordRequirementsView
                }
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
            
            // Consents Section
            consentsSection
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
                
                if let acceptedAt = viewModel.termsAcceptedAt {
                    Text("Aceptado el: \(DateFormatter.localizedString(from: acceptedAt, dateStyle: .short, timeStyle: .short))")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .padding(.top, 2)
                }
            }
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
                        Text("Creando cuenta...")
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
    
    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: passwordMeetsLength ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordMeetsLength ? .green : .gray)
                    .font(.system(size: 12))
                Text("Al menos 8 caracteres")
                    .font(.system(size: 12))
                    .foregroundColor(passwordMeetsLength ? .green : .gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: passwordHasLetter ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordHasLetter ? .green : .gray)
                    .font(.system(size: 12))
                Text("Al menos una letra")
                    .font(.system(size: 12))
                    .foregroundColor(passwordHasLetter ? .green : .gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: passwordHasNumber ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordHasNumber ? .green : .gray)
                    .font(.system(size: 12))
                Text("Al menos un número")
                    .font(.system(size: 12))
                    .foregroundColor(passwordHasNumber ? .green : .gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: passwordHasSpecialChar ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(passwordHasSpecialChar ? .green : .gray)
                    .font(.system(size: 12))
                Text("Al menos un carácter especial (!@#$%^&*)")
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
            Text("Consentimientos")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            // Data Processing Consent
            consentView(
                title: "Procesamiento de datos",
                description: "Acepto el procesamiento de mis datos personales según la política de privacidad.",
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
                title: "Cookies funcionales",
                description: "Acepto el uso de cookies funcionales para mejorar la experiencia de usuario.",
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
                    Text("Aceptado el: \(DateFormatter.localizedString(from: acceptedAt, dateStyle: .short, timeStyle: .short))")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
        }
    }
}
