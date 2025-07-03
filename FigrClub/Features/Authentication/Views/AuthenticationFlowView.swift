//
//  AuthenticationFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import SwiftUI

struct AuthenticationFlowView: View {
    @State private var showingLogin = true
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [.figrPrimary.opacity(0.1), .figrBackground]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: Spacing.xxLarge) {
                    // Header
                    VStack(spacing: Spacing.large) {
                        // Logo
                        Image("FigrClubLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .opacity(isAnimating ? 1.0 : 0.8)
                        
                        VStack(spacing: Spacing.small) {
                            Text("Bienvenido a")
                                .font(.figrTitle3)
                                .foregroundColor(.figrTextSecondary)
                                .opacity(isAnimating ? 1.0 : 0.0)
                            
                            Text("FigrClub")
                                .font(.figrLargeTitle.weight(.bold))
                                .foregroundColor(.figrPrimary)
                                .opacity(isAnimating ? 1.0 : 0.0)
                            
                            Text("La comunidad de coleccionistas")
                                .font(.figrCallout)
                                .foregroundColor(.figrTextSecondary)
                                .multilineTextAlignment(.center)
                                .opacity(isAnimating ? 1.0 : 0.0)
                        }
                    }
                    
                    Spacer()
                    
                    // Authentication Content
                    VStack(spacing: Spacing.large) {
                        // Tab Selector
                        HStack(spacing: 0) {
                            AuthTabButton(
                                title: "Iniciar Sesión",
                                isSelected: showingLogin
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingLogin = true
                                }
                            }
                            
                            AuthTabButton(
                                title: "Registrarse",
                                isSelected: !showingLogin
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingLogin = false
                                }
                            }
                        }
                        .background(.figrSurface)
                        .cornerRadius(AppConfig.UI.cornerRadius)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        // Content
                        Group {
                            if showingLogin {
                                LoginView()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading),
                                        removal: .move(edge: .trailing)
                                    ))
                            } else {
                                RegisterView()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    ))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: showingLogin)
                    }
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: Spacing.small) {
                        Text("Al continuar, aceptas nuestros")
                            .font(.figrCaption)
                            .foregroundColor(.figrTextSecondary)
                        
                        HStack(spacing: Spacing.small) {
                            Button("Términos de Servicio") {
                                // Handle terms
                            }
                            .font(.figrCaption.weight(.medium))
                            .foregroundColor(.figrPrimary)
                            
                            Text("y")
                                .font(.figrCaption)
                                .foregroundColor(.figrTextSecondary)
                            
                            Button("Política de Privacidad") {
                                // Handle privacy
                            }
                            .font(.figrCaption.weight(.medium))
                            .foregroundColor(.figrPrimary)
                        }
                    }
                    .opacity(isAnimating ? 1.0 : 0.0)
                }
                .padding(.horizontal, Spacing.large)
                .padding(.vertical, Spacing.xLarge)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pantalla de autenticación de FigrClub")
    }
}

// MARK: - Auth Tab Button
struct AuthTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.figrCallout.weight(.medium))
                .foregroundColor(isSelected ? .white : .figrTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.medium)
                .background(
                    isSelected ? Color.figrPrimary : Color.clear
                )
                .cornerRadius(AppConfig.UI.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .hapticFeedback()
    }
}

// MARK: - Login View (Simplified)
struct LoginView: View {
    @StateObject private var viewModel = DependencyContainer.shared.makeLoginViewModel()
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            // Email Field
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Email")
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                AuthTextField(
                    text: $viewModel.email,
                    placeholder: "tu@email.com",
                    keyboardType: .emailAddress,
                    validationState: viewModel.emailValidationState
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Contraseña")
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                FigrSecureField(
                    text: $viewModel.password,
                    placeholder: "Tu contraseña",
                    validationState: viewModel.passwordValidationState
                )
            }
            
            // Remember Me & Forgot Password
            HStack {
                FigrCheckbox(
                    isChecked: $viewModel.rememberMe,
                    title: "Recordarme"
                )
                
                Spacer()
                
                Button("¿Olvidaste tu contraseña?") {
                    // Handle forgot password
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
        }
        .toast(isPresented: $viewModel.showError) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.figrError)
                
                Text(viewModel.errorMessage ?? "Error desconocido")
                    .font(.figrCallout)
                    .foregroundColor(.figrTextPrimary)
            }
            .padding()
            .background(.figrSurface)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(radius: 4)
        }
    }
}

// MARK: - Register View (Simplified)
struct RegisterView: View {
    @StateObject private var viewModel = DependencyContainer.shared.makeRegisterViewModel()
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            // Name Fields
            HStack(spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Nombre")
                        .font(.figrCallout.weight(.medium))
                        .foregroundColor(.figrTextPrimary)
                    
                    AuthTextField(
                        text: $viewModel.firstName,
                        placeholder: "Nombre",
                        validationState: viewModel.firstNameValidationState
                    )
                }
                
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Apellido")
                        .font(.figrCallout.weight(.medium))
                        .foregroundColor(.figrTextPrimary)
                    
                    AuthTextField(
                        text: $viewModel.lastName,
                        placeholder: "Apellido",
                        validationState: viewModel.lastNameValidationState
                    )
                }
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Email")
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                AuthTextField(
                    text: $viewModel.email,
                    placeholder: "tu@email.com",
                    keyboardType: .emailAddress,
                    validationState: viewModel.emailValidationState
                )
            }
            
            // Username Field
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Nombre de usuario")
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                AuthTextField(
                    text: $viewModel.username,
                    placeholder: "@usuario",
                    validationState: viewModel.usernameValidationState
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Contraseña")
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                FigrSecureField(
                    text: $viewModel.password,
                    placeholder: "Mínimo 8 caracteres",
                    validationState: viewModel.passwordValidationState
                )
                
                if !viewModel.password.isEmpty {
                    PasswordStrengthIndicator(strength: viewModel.passwordStrength)
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Confirmar contraseña")
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                FigrSecureField(
                    text: $viewModel.confirmPassword,
                    placeholder: "Repite tu contraseña",
                    validationState: viewModel.confirmPasswordValidationState
                )
            }
            
            // Terms & Privacy
            VStack(spacing: Spacing.small) {
                FigrCheckbox(
                    isChecked: $viewModel.acceptedTerms,
                    title: "Acepto los Términos de Servicio"
                )
                
                FigrCheckbox(
                    isChecked: $viewModel.acceptedPrivacy,
                    title: "Acepto la Política de Privacidad"
                )
            }
            
            // Register Button
            FigrButton(
                title: "Crear Cuenta",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.isFormValid && !viewModel.isLoading
            ) {
                Task {
                    await viewModel.register()
                }
            }
            .hapticFeedback()
        }
        .toast(isPresented: $viewModel.showError) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.figrError)
                
                Text(viewModel.errorMessage ?? "Error desconocido")
                    .font(.figrCallout)
                    .foregroundColor(.figrTextPrimary)
            }
            .padding()
            .background(.figrSurface)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(radius: 4)
        }
    }
}

// MARK: - Supporting Components
struct AuthTextField: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var validationState: ValidationState = .idle
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(AuthTextFieldStyle(validationState: validationState))
            .keyboardType(keyboardType)
    }
}

struct FigrSecureField: View {
    @Binding var text: String
    let placeholder: String
    var validationState: ValidationState = .idle
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .textFieldStyle(AuthTextFieldStyle(validationState: validationState))
    }
}

struct AuthTextFieldStyle: TextFieldStyle {
    let validationState: ValidationState
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(.figrSurface)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    private var borderColor: Color {
        switch validationState {
        case .valid:
            return .figrSuccess
        case .invalid:
            return .figrError
        case .idle:
            return .figrBorder
        }
    }
}

struct FigrCheckbox: View {
    @Binding var isChecked: Bool
    let title: String
    
    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: Spacing.small) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .figrPrimary : .figrTextSecondary)
                
                Text(title)
                    .font(.figrCallout)
                    .foregroundColor(.figrTextPrimary)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AuthButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Text(title)
                        .font(.figrCallout.weight(.medium))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(isEnabled ? Color.figrPrimary : Color.figrTextSecondary)
            .cornerRadius(AppConfig.UI.cornerRadius)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

struct PasswordStrengthIndicator: View {
    let strength: PasswordStrength
    
    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(index < strength.rawValue + 1 ? strengthColor : .figrBorder)
                    .cornerRadius(2)
            }
            
            Spacer()
            
            Text(strength.description)
                .font(.figrCaption)
                .foregroundColor(strengthColor)
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case .weak:
            return .figrError
        case .fair:
            return .figrWarning
        case .good:
            return .figrInfo
        case .strong:
            return .figrSuccess
        }
    }
}

// MARK: - View Modifiers
extension View {
    func hapticFeedback() -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    func toast<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    content()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                isPresented.wrappedValue = false
                            }
                        }
                }
            }
                .animation(.easeInOut(duration: 0.3), value: isPresented.wrappedValue),
            alignment: .top
        )
    }
}

// MARK: - Preview
#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
            .dependencyInjection()
    }
}
#endif
