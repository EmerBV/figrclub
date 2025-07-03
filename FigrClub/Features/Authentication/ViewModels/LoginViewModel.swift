//
//  LoginViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var loginSuccess = false
    @Published var rememberMe = false
    
    // MARK: - Validation
    @Published var emailValidationState: ValidationState = .idle
    @Published var passwordValidationState: ValidationState = .idle
    @Published var isFormValid = false
    
    // MARK: - Use Cases
    private let loginUseCase: LoginUseCase
    private let authManager: AuthManager
    
    // MARK: - Initialization
    init(
        loginUseCase: LoginUseCase,
        authManager: AuthManager
    ) {
        self.loginUseCase = loginUseCase
        self.authManager = authManager
        super.init()
        
        setupValidation()
        setupAuthObserver()
    }
    
    // MARK: - Setup
    private func setupValidation() {
        // Email validation
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] email in
                self?.validateEmail(email) ?? .idle
            }
            .assign(to: &$emailValidationState)
        
        // Password validation
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] password in
                self?.validatePassword(password) ?? .idle
            }
            .assign(to: &$passwordValidationState)
        
        // Form validation
        Publishers.CombineLatest($emailValidationState, $passwordValidationState)
            .map { emailState, passwordState in
                emailState.isValid && passwordState.isValid
            }
            .assign(to: &$isFormValid)
    }
    
    private func setupAuthObserver() {
        authManager.authStatePublisher
            .map { state in
                if case .loading = state {
                    return true
                }
                return false
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        authManager.authStatePublisher
            .map { state in
                if case .authenticated = state {
                    return true
                }
                return false
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$loginSuccess)
    }
    
    // MARK: - Public Methods
    func login() async {
        guard isFormValid else {
            showErrorMessage("Por favor, completa todos los campos correctamente")
            return
        }
        
        await executeWithLoading {
            try await self.loginUseCase.execute(LoginInput(email: self.email, password: self.password))
        } onSuccess: { (authResponse, user) in
            Logger.shared.info("Login successful for user: \(user.id)", category: "auth")
            // AuthManager will handle the state update
        }
    }
    
    func resetForm() {
        email = ""
        password = ""
        rememberMe = false
        hideError()
    }
    
    // MARK: - Validation Methods
    private func validateEmail(_ email: String) -> ValidationState {
        if email.isEmpty {
            return .idle
        }
        
        if !email.contains("@") || !email.contains(".") {
            return .invalid("Formato de email inválido")
        }
        
        return .valid
    }
    
    private func validatePassword(_ password: String) -> ValidationState {
        if password.isEmpty {
            return .idle
        }
        
        if password.count < 6 {
            return .invalid("La contraseña debe tener al menos 6 caracteres")
        }
        
        return .valid
    }
}

// MARK: - Form Field State
struct FormFieldState {
    let text: String
    let validation: ValidationState
    let isFocused: Bool
    
    var showValidation: Bool {
        !text.isEmpty && !isFocused
    }
    
    var showError: Bool {
        showValidation && !validation.isValid
    }
    
    var showSuccess: Bool {
        showValidation && validation.isValid
    }
}
