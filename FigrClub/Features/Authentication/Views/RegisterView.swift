//
//  RegisterView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DependencyContainer.shared.resolve(RegisterViewModel.self)
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var currentStep: RegistrationStep = .personalInfo
    @State private var showLogin = false
    
    enum RegistrationStep: Int, CaseIterable {
        case personalInfo = 0
        case accountInfo = 1
        case preferences = 2
        case legal = 3
        
        var title: String {
            switch self {
            case .personalInfo: return "Información Personal"
            case .accountInfo: return "Cuenta"
            case .preferences: return "Preferencias"
            case .legal: return "Términos Legales"
            }
        }
        
        var progress: Double {
            return Double(self.rawValue + 1) / Double(RegistrationStep.allCases.count)
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress Bar
                    ProgressView(value: currentStep.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .figrPrimary))
                        .background(.figrBorder)
                        .frame(height: 4)
                    
                    ScrollView {
                        VStack(spacing: Spacing.xxxLarge) {
                            // Header
                            VStack(spacing: Spacing.medium) {
                                Text("Crear Cuenta")
                                    .font(.figrTitle)
                                    .foregroundColor(.figrTextPrimary)
                                
                                Text(currentStep.title)
                                    .font(.figrHeadline)
                                    .foregroundColor(.figrTextSecondary)
                            }
                            .padding(.top, Spacing.large)
                            
                            // Step Content
                            Group {
                                switch currentStep {
                                case .personalInfo:
                                    PersonalInfoStep(viewModel: viewModel)
                                case .accountInfo:
                                    AccountInfoStep(viewModel: viewModel)
                                case .preferences:
                                    PreferencesStep(viewModel: viewModel)
                                case .legal:
                                    LegalStep(viewModel: viewModel)
                                }
                            }
                            .animation(.easeInOut, value: currentStep)
                            
                            Spacer(minLength: Spacing.large)
                        }
                        .padding(.horizontal, Spacing.xLarge)
                        .frame(minHeight: geometry.size.height - 100) // Account for progress bar and navigation
                    }
                    
                    // Bottom Buttons
                    VStack(spacing: Spacing.medium) {
                        if currentStep == .legal {
                            FigrButton(
                                title: "Crear Cuenta",
                                isLoading: viewModel.isLoading,
                                isEnabled: canProceed && !viewModel.isLoading
                            ) {
                                Task {
                                    await viewModel.register()
                                }
                            }
                        } else {
                            FigrButton(
                                title: "Continuar",
                                isEnabled: canProceed
                            ) {
                                nextStep()
                            }
                        }
                        
                        if currentStep != .personalInfo {
                            FigrButton(
                                title: "Atrás",
                                style: .ghost
                            ) {
                                previousStep()
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xLarge)
                    .padding(.bottom, Spacing.large)
                    .background(.figrBackground)
                }
            }
            .background(.figrBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Iniciar Sesión") {
                        showLogin = true
                    }
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrPrimary)
                }
            }
        }
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
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
        .onChange(of: viewModel.registrationSuccess) { success in
            if success {
                dismiss()
            }
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "RegisterView")
        }
    }
    
    // MARK: - Computed Properties
    
    private var canProceed: Bool {
        switch currentStep {
        case .personalInfo:
            return viewModel.firstNameValidationState.isValid &&
            viewModel.lastNameValidationState.isValid
        case .accountInfo:
            return viewModel.emailValidationState.isValid &&
            viewModel.usernameValidationState.isValid &&
            viewModel.passwordValidationState.isValid &&
            viewModel.confirmPasswordValidationState.isValid
        case .preferences:
            return true // Optional step
        case .legal:
            return viewModel.legalValidationState.isValid
        }
    }
    
    // MARK: - Private Methods
    
    private func nextStep() {
        guard let nextStep = RegistrationStep(rawValue: currentStep.rawValue + 1) else { return }
        
        withAnimation(.easeInOut) {
            currentStep = nextStep
        }
        
        HapticManager.shared.impact(.light)
        
        Analytics.shared.logEvent("registration_step_completed", parameters: [
            "step": currentStep.title,
            "step_number": currentStep.rawValue + 1
        ])
    }
    
    private func previousStep() {
        guard let previousStep = RegistrationStep(rawValue: currentStep.rawValue - 1) else { return }
        
        withAnimation(.easeInOut) {
            currentStep = previousStep
        }
        
        HapticManager.shared.impact(.light)
    }
}

// MARK: - Registration Steps

struct PersonalInfoStep: View {
    @ObservedObject var viewModel: RegisterViewModel
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            Text("Cuéntanos sobre ti")
                .font(.figrBody)
                .foregroundColor(.figrTextSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: Spacing.large) {
                FigrTextField(
                    title: "Nombre",
                    placeholder: "Tu nombre",
                    text: $viewModel.firstName,
                    validation: viewModel.firstNameValidationState,
                    leadingIcon: "person"
                )
                .textContentType(.givenName)
                .autocapitalization(.words)
                
                FigrTextField(
                    title: "Apellido",
                    placeholder: "Tu apellido",
                    text: $viewModel.lastName,
                    validation: viewModel.lastNameValidationState,
                    leadingIcon: "person"
                )
                .textContentType(.familyName)
                .autocapitalization(.words)
            }
        }
    }
}

struct AccountInfoStep: View {
    @ObservedObject var viewModel: RegisterViewModel
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            Text("Configura tu cuenta")
                .font(.figrBody)
                .foregroundColor(.figrTextSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: Spacing.large) {
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
                
                FigrTextField(
                    title: "Nombre de usuario",
                    placeholder: "usuario123",
                    text: $viewModel.username,
                    validation: viewModel.usernameValidationState,
                    leadingIcon: "at"
                )
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                VStack(spacing: Spacing.medium) {
                    FigrTextField(
                        title: "Contraseña",
                        placeholder: "Mínimo 8 caracteres",
                        text: $viewModel.password,
                        isSecure: true,
                        validation: viewModel.passwordValidationState,
                        leadingIcon: "lock"
                    )
                    .textContentType(.newPassword)
                    
                    // Password Strength Indicator
                    if !viewModel.password.isEmpty {
                        PasswordStrengthView(strength: viewModel.passwordStrength)
                    }
                }
                
                FigrTextField(
                    title: "Confirmar contraseña",
                    placeholder: "Repite tu contraseña",
                    text: $viewModel.confirmPassword,
                    isSecure: true,
                    validation: viewModel.confirmPasswordValidationState,
                    leadingIcon: "lock"
                )
                .textContentType(.newPassword)
            }
        }
    }
}

struct PreferencesStep: View {
    @ObservedObject var viewModel: RegisterViewModel
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            Text("Personaliza tu experiencia")
                .font(.figrBody)
                .foregroundColor(.figrTextSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: Spacing.large) {
                // User Type Selection
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Tipo de cuenta")
                        .font(.figrSubheadline)
                        .foregroundColor(.figrTextSecondary)
                    
                    VStack(spacing: Spacing.small) {
                        ForEach(UserType.allCases.filter { $0 != .admin }, id: \.self) { userType in
                            UserTypeCard(
                                userType: userType,
                                isSelected: viewModel.userType == userType
                            ) {
                                viewModel.userType = userType
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LegalStep: View {
    @ObservedObject var viewModel: RegisterViewModel
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            Text("Términos y condiciones")
                .font(.figrBody)
                .foregroundColor(.figrTextSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: Spacing.large) {
                LegalCheckbox(
                    text: "Acepto los [Términos de Servicio](https://figrclub.com/terms)",
                    isChecked: $viewModel.acceptedTerms,
                    isRequired: true
                )
                
                LegalCheckbox(
                    text: "Acepto la [Política de Privacidad](https://figrclub.com/privacy)",
                    isChecked: $viewModel.acceptedPrivacy,
                    isRequired: true
                )
                
                LegalCheckbox(
                    text: "Deseo recibir emails promocionales (opcional)",
                    isChecked: $viewModel.acceptedMarketing,
                    isRequired: false
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct PasswordStrengthView: View {
    let strength: PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Seguridad de la contraseña:")
                    .font(.figrCaption)
                    .foregroundColor(.figrTextSecondary)
                
                Text(strength.description)
                    .font(.figrCaption.weight(.medium))
                    .foregroundColor(strength.color)
            }
            
            ProgressView(value: strength.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: strength.color))
                .background(.figrBorder)
                .frame(height: 4)
                .cornerRadius(2)
        }
    }
}

struct UserTypeCard: View {
    let userType: UserType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(userType.displayName)
                        .font(.figrCallout.weight(.medium))
                        .foregroundColor(.figrTextPrimary)
                    
                    Text(userType.description)
                        .font(.figrCaption)
                        .foregroundColor(.figrTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .figrPrimary : .figrBorder)
                    .font(.figrBody)
            }
            .padding()
            .background(isSelected ? .figrPrimary.opacity(0.1) : .figrSurface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? .figrPrimary : .figrBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LegalCheckbox: View {
    let text: String
    @Binding var isChecked: Bool
    let isRequired: Bool
    
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .figrPrimary : .figrBorder)
                    .font(.figrBody)
                
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(LocalizedStringKey(text))
                        .font(.figrFootnote)
                        .foregroundColor(.figrTextPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if isRequired {
                        Text("Requerido")
                            .font(.figrCaption2)
                            .foregroundColor(.figrError)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}



