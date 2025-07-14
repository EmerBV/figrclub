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
    
    // Validation states
    @Published var loginEmailValidation: ValidationResult = .valid
    @Published var loginPasswordValidation: ValidationResult = .valid
    @Published var registerEmailValidation: ValidationResult = .valid
    @Published var registerPasswordValidation: ValidationResult = .valid
    @Published var usernameValidation: ValidationResult = .valid
    @Published var fullNameValidation: ValidationResult = .valid
    @Published var confirmPasswordValidation: ValidationResult = .valid
    
    // MARK: - Dependencies
    private nonisolated let authStateManager: AuthStateManager
    private nonisolated let validationService: ValidationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var canLogin: Bool {
        !loginEmail.isEmpty &&
        !loginPassword.isEmpty &&
        !isLoading &&
        loginEmailValidation.isValid &&
        loginPasswordValidation.isValid
    }
    
    var canRegister: Bool {
        !registerEmail.isEmpty &&
        !registerPassword.isEmpty &&
        !registerUsername.isEmpty &&
        !registerFullName.isEmpty &&
        registerPassword == registerConfirmPassword &&
        acceptTerms &&
        !isLoading &&
        registerEmailValidation.isValid &&
        registerPasswordValidation.isValid &&
        usernameValidation.isValid &&
        fullNameValidation.isValid &&
        confirmPasswordValidation.isValid
    }
    
    // MARK: - Initializer
    nonisolated init(authStateManager: AuthStateManager, validationService: ValidationServiceProtocol) {
        self.authStateManager = authStateManager
        self.validationService = validationService
        
        Task { @MainActor in
            self.setupValidation()
            self.setupAuthStateSubscription()
            Logger.info("✅ AuthViewModel: Initialized successfully")
        }
    }
    
    // MARK: - Public Methods
    
    func login() async {
        guard canLogin else {
            Logger.warning("⚠️ AuthViewModel: Cannot login - validation failed")
            return
        }
        
        Logger.info("🔐 AuthViewModel: Starting login process for: \(loginEmail)")
        isLoading = true
        hideError()
        
        let result = await authStateManager.login(email: loginEmail, password: loginPassword)
        
        switch result {
        case .success(let user):
            Logger.info("✅ AuthViewModel: Login successful for user: \(user.displayName)")
            clearLoginForm()
        case .failure(let error):
            Logger.error("❌ AuthViewModel: Login failed: \(error)")
            showErrorMessage(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func register() async {
        guard canRegister else {
            Logger.warning("⚠️ AuthViewModel: Cannot register - validation failed")
            return
        }
        
        Logger.info("📝 AuthViewModel: Starting registration process for: \(registerEmail)")
        isLoading = true
        hideError()
        
        let result = await authStateManager.register(
            email: registerEmail,
            password: registerPassword,
            username: registerUsername,
            fullName: registerFullName.isEmpty ? nil : registerFullName
        )
        
        switch result {
        case .success(let user):
            Logger.info("✅ AuthViewModel: Registration successful for user: \(user.displayName)")
            clearRegisterForm()
        case .failure(let error):
            Logger.error("❌ AuthViewModel: Registration failed: \(error)")
            showErrorMessage(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func switchToLogin() {
        Logger.info("🔄 AuthViewModel: Switching to login screen")
        
        // NO usar withAnimation aquí - dejar que la vista maneje la animación
        isShowingLogin = true
        hideError()
        clearRegisterForm()
    }
    
    func switchToRegister() {
        Logger.info("🔄 AuthViewModel: Switching to register screen")
        
        // NO usar withAnimation aquí - dejar que la vista maneje la animación
        isShowingLogin = false
        hideError()
        clearLoginForm()
    }
    
    func hideError() {
        errorMessage = nil
        showError = false
    }
    
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide after 5 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            hideError()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupValidation() {
        // Login email validation
        $loginEmail
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] email in
                guard !email.isEmpty else { return ValidationResult.valid }
                return self?.validationService.validateEmail(email) ?? .valid
            }
            .assign(to: \.loginEmailValidation, on: self)
            .store(in: &cancellables)
        
        // Login password validation
        $loginPassword
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] password in
                guard !password.isEmpty else { return ValidationResult.valid }
                return self?.validationService.validatePassword(password) ?? .valid
            }
            .assign(to: \.loginPasswordValidation, on: self)
            .store(in: &cancellables)
        
        // Register email validation
        $registerEmail
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] email in
                guard !email.isEmpty else { return ValidationResult.valid }
                return self?.validationService.validateEmail(email) ?? .valid
            }
            .assign(to: \.registerEmailValidation, on: self)
            .store(in: &cancellables)
        
        // Register password validation
        $registerPassword
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] password in
                guard !password.isEmpty else { return ValidationResult.valid }
                return self?.validationService.validatePassword(password) ?? .valid
            }
            .assign(to: \.registerPasswordValidation, on: self)
            .store(in: &cancellables)
        
        // Username validation
        $registerUsername
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] username in
                guard !username.isEmpty else { return ValidationResult.valid }
                return self?.validationService.validateUsername(username) ?? .valid
            }
            .assign(to: \.usernameValidation, on: self)
            .store(in: &cancellables)
        
        // Full name validation
        $registerFullName
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] fullName in
                guard !fullName.isEmpty else { return ValidationResult.valid }
                return self?.validationService.validateFullName(fullName) ?? .valid
            }
            .assign(to: \.fullNameValidation, on: self)
            .store(in: &cancellables)
        
        // Confirm password validation
        Publishers.CombineLatest($registerPassword, $registerConfirmPassword)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { password, confirmPassword in
                guard !confirmPassword.isEmpty else { return ValidationResult.valid }
                return password == confirmPassword ? .valid : .invalid("Las contraseñas no coinciden")
            }
            .assign(to: \.confirmPasswordValidation, on: self)
            .store(in: &cancellables)
        
        Logger.debug("✅ AuthViewModel: Validation setup completed")
    }
    
    private func setupAuthStateSubscription() {
        authStateManager.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authState in
                guard let self = self else { return }
                
                Logger.debug("🔄 AuthViewModel: AuthState changed to: \(authState)")
                
                switch authState {
                case .loading:
                    // Solo mostrar loading si estamos haciendo login/register
                    // NO cambiar isLoading aquí para evitar conflictos
                    break
                case .authenticated:
                    // Limpiar estado cuando el usuario se autentica exitosamente
                    self.isLoading = false
                    self.hideError()
                    // NO resetear isShowingLogin aquí
                case .unauthenticated:
                    self.isLoading = false
                    self.hideError()
                    // Resetear a login cuando no está autenticado
                    if !self.isShowingLogin {
                        self.isShowingLogin = true
                    }
                case .error(let message):
                    self.isLoading = false
                    self.showErrorMessage(message)
                }
            }
            .store(in: &cancellables)
        
        Logger.debug("✅ AuthViewModel: AuthState subscription setup completed")
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

extension AuthViewModel {
    
    // MARK: - Public Methods with Error Return
    
    /// Perform login and return error if any
    func loginWithErrorHandling() async -> NetworkError? {
        guard canLogin else {
            return NetworkError.badRequest(APIError(
                message: "Por favor completa todos los campos correctamente",
                code: "VALIDATION_ERROR",
                details: nil
            ))
        }
        
        Logger.info("🔐 AuthViewModel: Login with error handling for: \(loginEmail)")
        isLoading = true
        hideError()
        
        let result = await authStateManager.login(email: loginEmail, password: loginPassword)
        
        switch result {
        case .success(let user):
            clearLoginForm()
            isLoading = false
            Logger.info("✅ Login successful for user: \(user.displayName)")
            return nil // No error
            
        case .failure(let error):
            isLoading = false
            Logger.error("❌ Login failed: \(error)")
            return NetworkError.from(error)
        }
    }
    
    /// Perform registration and return error if any
    func registerWithErrorHandling() async -> NetworkError? {
        guard canRegister else {
            return NetworkError.badRequest(APIError(
                message: "Por favor completa todos los campos correctamente y acepta los términos",
                code: "VALIDATION_ERROR",
                details: nil
            ))
        }
        
        Logger.info("📝 AuthViewModel: Register with error handling for: \(registerEmail)")
        isLoading = true
        hideError()
        
        let result = await authStateManager.register(
            email: registerEmail,
            password: registerPassword,
            username: registerUsername,
            fullName: registerFullName.isEmpty ? nil : registerFullName
        )
        
        switch result {
        case .success(let user):
            clearRegisterForm()
            isLoading = false
            Logger.info("✅ Registration successful for user: \(user.displayName)")
            return nil // No error
            
        case .failure(let error):
            isLoading = false
            Logger.error("❌ Registration failed: \(error)")
            return NetworkError.from(error)
        }
    }
    
    // MARK: - Public Clear Methods
    
    /// Public method to clear login form
    func clearLoginFormPublic() {
        clearLoginForm()
    }
    
    /// Public method to clear register form
    func clearRegisterFormPublic() {
        clearRegisterForm()
    }
    
    /// Clear all forms and reset state
    func clearAllForms() {
        clearLoginForm()
        clearRegisterForm()
        hideError()
        // NO resetear isShowingLogin aquí
    }
}

// MARK: - Validation Helper Extension
extension AuthViewModel {
    
    /// Get validation errors for current login form
    var loginValidationErrors: [String] {
        var errors: [String] = []
        
        if case .invalid(let errorMessage) = loginEmailValidation {
            errors.append(errorMessage)
        }
        
        if case .invalid(let errorMessage) = loginPasswordValidation {
            errors.append(errorMessage)
        }
        
        return errors
    }
    
    /// Get validation errors for current register form
    var registerValidationErrors: [String] {
        var errors: [String] = []
        
        if case .invalid(let errorMessage) = registerEmailValidation {
            errors.append(errorMessage)
        }
        
        if case .invalid(let errorMessage) = registerPasswordValidation {
            errors.append(errorMessage)
        }
        
        if case .invalid(let errorMessage) = usernameValidation {
            errors.append(errorMessage)
        }
        
        if case .invalid(let errorMessage) = fullNameValidation {
            errors.append(errorMessage)
        }
        
        if case .invalid(let errorMessage) = confirmPasswordValidation {
            errors.append(errorMessage)
        }
        
        if !acceptTerms {
            errors.append("Debes aceptar los términos y condiciones")
        }
        
        return errors
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
