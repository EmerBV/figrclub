//
//  RegisterView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, username, fullName, password, confirmPassword
    }
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            VStack(spacing: Spacing.medium) {
                // Email field
                AuthTextField(
                    text: $viewModel.registerEmail,
                    placeholder: "Email",
                    keyboardType: .emailAddress,
                    validationState: getValidationState(viewModel.emailValidation)
                )
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                
                // Username field
                AuthTextField(
                    text: $viewModel.registerUsername,
                    placeholder: "Nombre de usuario",
                    validationState: getValidationState(viewModel.usernameValidation)
                )
                .focused($focusedField, equals: .username)
                .textContentType(.username)
                .autocapitalization(.none)
                
                // Full name field
                AuthTextField(
                    text: $viewModel.registerFullName,
                    placeholder: "Nombre completo",
                    validationState: getValidationState(viewModel.fullNameValidation)
                )
                .focused($focusedField, equals: .fullName)
                .textContentType(.name)
                
                // Password field
                AuthSecureField(
                    text: $viewModel.registerPassword,
                    placeholder: "Contraseña",
                    validationState: getValidationState(viewModel.passwordValidation)
                )
                .focused($focusedField, equals: .password)
                .textContentType(.newPassword)
                
                // Confirm password field
                AuthSecureField(
                    text: $viewModel.registerConfirmPassword,
                    placeholder: "Confirmar contraseña",
                    validationState: getValidationState(viewModel.confirmPasswordValidation)
                )
                .focused($focusedField, equals: .confirmPassword)
                .textContentType(.newPassword)
            }
            
            // Terms and conditions
            HStack(spacing: Spacing.small) {
                Button {
                    viewModel.acceptTerms.toggle()
                } label: {
                    Image(systemName: viewModel.acceptTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(viewModel.acceptTerms ? .blue : .gray)
                }
                
                Text("Acepto los términos y condiciones")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Register button
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
                    }
                    Text(viewModel.isLoading ? "Creando cuenta..." : "Crear Cuenta")
                }
            }
            .buttonStyle(FigrButtonStyle(isEnabled: viewModel.canRegister, isLoading: viewModel.isLoading))
            .disabled(!viewModel.canRegister)
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .username
            case .username:
                focusedField = .fullName
            case .fullName:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                Task {
                    await viewModel.register()
                }
            case .none:
                break
            }
        }
    }
    
    private func getValidationState(_ validation: ValidationResult) -> ValidationState {
        switch validation {
        case .valid:
            return .idle
        case .invalid:
            return .invalid
        }
    }
}
