//
//  AuthenticationFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import SwiftUI

struct AuthenticationFlowView: View {
    @EnvironmentObject private var authManager: AuthManager
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
                                Button("Iniciar Sesión") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.isShowingLogin = true
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(viewModel.isShowingLogin ? Color.blue : Color.clear)
                                .foregroundColor(viewModel.isShowingLogin ? .white : .blue)
                                .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                                
                                Button("Registrarse") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.isShowingLogin = false
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(!viewModel.isShowingLogin ? Color.blue : Color.clear)
                                .foregroundColor(!viewModel.isShowingLogin ? .white : .blue)
                                .cornerRadius(8, corners: [.topRight, .bottomRight])
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
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

// MARK: - Login Form
struct LoginFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("tu@email.com", text: $viewModel.loginEmail)
                    .textFieldStyle(FigrTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                SecureField("Tu contraseña", text: $viewModel.loginPassword)
                    .textFieldStyle(FigrTextFieldStyle())
            }
            
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
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canLogin ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
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
}

// MARK: - Register Form
struct RegisterFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Full Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre completo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Tu nombre completo", text: $viewModel.registerFullName)
                    .textFieldStyle(FigrTextFieldStyle())
                    .autocapitalization(.words)
            }
            
            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre de usuario")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("usuario", text: $viewModel.registerUsername)
                    .textFieldStyle(FigrTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("tu@email.com", text: $viewModel.registerEmail)
                    .textFieldStyle(FigrTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                SecureField("Tu contraseña", text: $viewModel.registerPassword)
                    .textFieldStyle(FigrTextFieldStyle())
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirmar contraseña")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                SecureField("Confirma tu contraseña", text: $viewModel.registerConfirmPassword)
                    .textFieldStyle(FigrTextFieldStyle())
            }
            
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
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canRegister ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canRegister)
        }
        .padding(.top, 20)
    }
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
            .environmentObject(DependencyInjector.shared.resolve(AuthManager.self))
    }
}
#endif


