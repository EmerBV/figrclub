//
//  AuthViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isShowingLogin = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Login form
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    
    // Register form
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerUsername = ""
    @Published var registerFullName = ""
    @Published var registerConfirmPassword = ""
    @Published var acceptTerms = false
    
    // Validation
    @Published var emailValidation: ValidationResult = .valid
    @Published var passwordValidation: ValidationResult = .valid
    @Published var usernameValidation: ValidationResult = .valid
    @Published var fullNameValidation: ValidationResult = .valid
    @Published var confirmPasswordValidation: ValidationResult = .valid
    
    // MARK: - Dependencies
    private nonisolated let authManager: AuthManager
    private nonisolated let validationService: ValidationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var canLogin: Bool {
        !loginEmail.isEmpty && !loginPassword.isEmpty && !isLoading
    }
    
    var canRegister: Bool {
        !registerEmail.isEmpty &&
        !registerPassword.isEmpty &&
        !registerUsername.isEmpty &&
        !registerFullName.isEmpty &&
        registerPassword == registerConfirmPassword &&
        acceptTerms &&
        !isLoading &&
        emailValidation.isValid &&
        passwordValidation.isValid &&
        usernameValidation.isValid &&
        fullNameValidation.isValid &&
        confirmPasswordValidation.isValid
    }
    
    // MARK: - Swift 6 Compatible Initializer
    /// Initializer compatible con Swift 6 usando Sendable pattern
    nonisolated init(authManager: AuthManager, validationService: ValidationServiceProtocol) {
        // Asignar dependencias de forma directa (compatibilidad Swift 6)
        self.authManager = authManager
        self.validationService = validationService
        
        // Configurar inmediatamente las validaciones en el próximo tick del main actor
        Task { @MainActor in
            self.setupValidation()
        }
    }
    
    // MARK: - Public Methods
    
    func login() async {
        guard canLogin else { return }
        
        isLoading = true
        hideError()
        
        let result = await authManager.login(email: loginEmail, password: loginPassword)
        
        switch result {
        case .success:
            // Success is handled by AuthManager state changes
            clearLoginForm()
        case .failure(let error):
            showErrorMessage(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func register() async {
        guard canRegister else { return }
        
        isLoading = true
        hideError()
        
        let result = await authManager.register(
            email: registerEmail,
            password: registerPassword,
            username: registerUsername,
            fullName: registerFullName.isEmpty ? nil : registerFullName
        )
        
        switch result {
        case .success:
            // Success is handled by AuthManager state changes
            clearRegisterForm()
        case .failure(let error):
            showErrorMessage(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func switchToLogin() {
        withAnimation(.easeInOut(duration: AppConfig.UI.animationDuration)) {
            isShowingLogin = true
        }
        hideError()
    }
    
    func switchToRegister() {
        withAnimation(.easeInOut(duration: AppConfig.UI.animationDuration)) {
            isShowingLogin = false
        }
        hideError()
    }
    
    // MARK: - Public Error Handling
    func hideError() {
        errorMessage = nil
        showError = false
    }
    
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide after 5 seconds using MainActor-safe approach
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            hideError()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupValidation() {
        // Email validation for both forms
        Publishers.CombineLatest($loginEmail, $registerEmail)
            .receive(on: DispatchQueue.main)
            .map { [weak self] loginEmail, registerEmail in
                let email = self?.isShowingLogin == true ? loginEmail : registerEmail
                return self?.validationService.validateEmail(email) ?? .valid
            }
            .assign(to: \.emailValidation, on: self)
            .store(in: &cancellables)
        
        // Password validation
        $registerPassword
            .receive(on: DispatchQueue.main)
            .map { [weak self] password in
                self?.validationService.validatePassword(password) ?? .valid
            }
            .assign(to: \.passwordValidation, on: self)
            .store(in: &cancellables)
        
        // Username validation
        $registerUsername
            .receive(on: DispatchQueue.main)
            .map { [weak self] username in
                self?.validationService.validateUsername(username) ?? .valid
            }
            .assign(to: \.usernameValidation, on: self)
            .store(in: &cancellables)
        
        // Full name validation
        $registerFullName
            .receive(on: DispatchQueue.main)
            .map { [weak self] fullName in
                self?.validationService.validateFullName(fullName) ?? .valid
            }
            .assign(to: \.fullNameValidation, on: self)
            .store(in: &cancellables)
        
        // Confirm password validation
        Publishers.CombineLatest($registerPassword, $registerConfirmPassword)
            .receive(on: DispatchQueue.main)
            .map { password, confirmPassword in
                if confirmPassword.isEmpty {
                    return ValidationResult.valid
                }
                return password == confirmPassword ? .valid : .invalid("Las contraseñas no coinciden")
            }
            .assign(to: \.confirmPasswordValidation, on: self)
            .store(in: &cancellables)
    }
    
    private func clearLoginForm() {
        loginEmail = ""
        loginPassword = ""
    }
    
    private func clearRegisterForm() {
        registerEmail = ""
        registerPassword = ""
        registerUsername = ""
        registerFullName = ""
        registerConfirmPassword = ""
        acceptTerms = false
    }
}

// MARK: - Preview Support
#if DEBUG
extension AuthViewModel {
    static func preview() -> AuthViewModel {
        return DependencyInjector.shared.resolve(AuthViewModel.self)
    }
}
#endif
