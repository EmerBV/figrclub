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
    
    // MARK: - Validation Management
    private let loginValidationManager: FormValidationManager
    private let registerValidationManager: FormValidationManager
    
    // MARK: - Dependencies
    private nonisolated let authStateManager: AuthStateManager
    private nonisolated let validationService: ValidationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var canLogin: Bool {
        !loginEmail.isEmpty &&
        !loginPassword.isEmpty &&
        !isLoading &&
        loginValidationManager.isFormValid
    }
    
    var canRegister: Bool {
        !registerEmail.isEmpty &&
        !registerPassword.isEmpty &&
        !registerUsername.isEmpty &&
        !registerFullName.isEmpty &&
        registerPassword == registerConfirmPassword &&
        acceptTerms &&
        !isLoading &&
        registerValidationManager.isFormValid
    }
    
    // MARK: - Validation Access
    var loginEmailValidation: ValidationResult {
        loginValidationManager.getValidation(for: "email")
    }
    
    var loginPasswordValidation: ValidationResult {
        loginValidationManager.getValidation(for: "password")
    }
    
    var registerEmailValidation: ValidationResult {
        registerValidationManager.getValidation(for: "email")
    }
    
    var registerPasswordValidation: ValidationResult {
        registerValidationManager.getValidation(for: "password")
    }
    
    var usernameValidation: ValidationResult {
        registerValidationManager.getValidation(for: "username")
    }
    
    var fullNameValidation: ValidationResult {
        registerValidationManager.getValidation(for: "fullName")
    }
    
    var confirmPasswordValidation: ValidationResult {
        registerValidationManager.getValidation(for: "confirmPassword")
    }
    
    // MARK: - Initializer
    nonisolated init(authStateManager: AuthStateManager, validationService: ValidationServiceProtocol) {
        self.authStateManager = authStateManager
        self.validationService = validationService
        
        // Create validation managers on MainActor
        self.loginValidationManager = MainActor.assumeIsolated {
            FormValidationManager()
        }
        self.registerValidationManager = MainActor.assumeIsolated {
            FormValidationManager()
        }
        
        Task { @MainActor in
            self.setupValidation()
            self.setupAuthStateSubscription()
            Logger.info("✅ AuthViewModel: Initialized successfully")
        }
    }
    
    // MARK: - Public Methods
    
    func login() async {
        await performAuthAction(canPerform: canLogin, action: "login") {
            await authStateManager.login(email: loginEmail, password: loginPassword)
        } onSuccess: { user in
            Logger.info("✅ AuthViewModel: Login successful for user: \(user.displayName)")
            clearLoginForm()
        }
    }
    
    func register() async {
        await performAuthAction(canPerform: canRegister, action: "register") {
            await authStateManager.register(
                email: registerEmail,
                password: registerPassword,
                username: registerUsername,
                fullName: registerFullName.isEmpty ? nil : registerFullName
            )
        } onSuccess: { user in
            Logger.info("✅ AuthViewModel: Registration successful for user: \(user.displayName)")
            clearRegisterForm()
        }
    }
    
    func switchToLogin() {
        Logger.info("🔄 AuthViewModel: Switching to login screen")
        isShowingLogin = true
        hideError()
        clearRegisterForm()
    }
    
    func switchToRegister() {
        Logger.info("🔄 AuthViewModel: Switching to register screen")
        isShowingLogin = false
        hideError()
        clearLoginForm()
    }
    
    func hideError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Error Handling Methods
    
    func loginWithErrorHandling() async -> NetworkError? {
        guard canLogin else {
            return createValidationError("Por favor completa todos los campos correctamente")
        }
        
        return await performAuthActionWithErrorHandling(action: "login") {
            await authStateManager.login(email: loginEmail, password: loginPassword)
        } onSuccess: {
            clearLoginForm()
        }
    }
    
    func registerWithErrorHandling() async -> NetworkError? {
        guard canRegister else {
            return createValidationError("Por favor completa todos los campos correctamente y acepta los términos")
        }
        
        return await performAuthActionWithErrorHandling(action: "register") {
            await authStateManager.register(
                email: registerEmail,
                password: registerPassword,
                username: registerUsername,
                fullName: registerFullName.isEmpty ? nil : registerFullName
            )
        } onSuccess: {
            clearRegisterForm()
        }
    }
    
    // MARK: - Form Management
    
    func clearLoginFormPublic() {
        clearLoginForm()
    }
    
    func clearRegisterFormPublic() {
        clearRegisterForm()
    }
    
    func clearAllForms() {
        clearLoginForm()
        clearRegisterForm()
        hideError()
    }
    
    // MARK: - Validation Helpers
    
    var loginValidationErrors: [String] {
        return loginValidationManager.getErrors()
    }
    
    var registerValidationErrors: [String] {
        return registerValidationManager.getErrors()
    }
}

// MARK: - Private Methods
private extension AuthViewModel {
    
    func setupValidation() {
        setupLoginValidation()
        setupRegisterValidation()
        Logger.debug("✅ AuthViewModel: Validation setup completed")
    }
    
    func setupLoginValidation() {
        // Email validation
        let emailValidation = ValidationHelper.createValidationPublisher(
            for: $loginEmail.eraseToAnyPublisher(),
            using: { [weak self] email in
                self?.validationService.validateEmail(email) ?? .valid
            }
        )
        loginValidationManager.addValidation(for: "email", publisher: emailValidation)
        
        // Password validation
        let passwordValidation = ValidationHelper.createValidationPublisher(
            for: $loginPassword.eraseToAnyPublisher(),
            using: { [weak self] password in
                self?.validationService.validatePassword(password) ?? .valid
            }
        )
        loginValidationManager.addValidation(for: "password", publisher: passwordValidation)
    }
    
    func setupRegisterValidation() {
        // Email validation
        let emailValidation = ValidationHelper.createValidationPublisher(
            for: $registerEmail.eraseToAnyPublisher(),
            using: { [weak self] email in
                self?.validationService.validateEmail(email) ?? .valid
            }
        )
        registerValidationManager.addValidation(for: "email", publisher: emailValidation)
        
        // Password validation
        let passwordValidation = ValidationHelper.createValidationPublisher(
            for: $registerPassword.eraseToAnyPublisher(),
            using: { [weak self] password in
                self?.validationService.validatePassword(password) ?? .valid
            }
        )
        registerValidationManager.addValidation(for: "password", publisher: passwordValidation)
        
        // Username validation
        let usernameValidation = ValidationHelper.createValidationPublisher(
            for: $registerUsername.eraseToAnyPublisher(),
            using: { [weak self] username in
                self?.validationService.validateUsername(username) ?? .valid
            }
        )
        registerValidationManager.addValidation(for: "username", publisher: usernameValidation)
        
        // Full name validation
        let fullNameValidation = ValidationHelper.createValidationPublisher(
            for: $registerFullName.eraseToAnyPublisher(),
            using: { [weak self] fullName in
                self?.validationService.validateFullName(fullName) ?? .valid
            }
        )
        registerValidationManager.addValidation(for: "fullName", publisher: fullNameValidation)
        
        // Confirm password validation
        let confirmPasswordValidation = ValidationHelper.createPasswordConfirmationPublisher(
            password: $registerPassword.eraseToAnyPublisher(),
            confirmPassword: $registerConfirmPassword.eraseToAnyPublisher()
        )
        registerValidationManager.addValidation(for: "confirmPassword", publisher: confirmPasswordValidation)
    }
    
    func setupAuthStateSubscription() {
        authStateManager.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authState in
                self?.handleAuthStateChange(authState)
            }
            .store(in: &cancellables)
        
        Logger.debug("✅ AuthViewModel: AuthState subscription setup completed")
    }
    
    func handleAuthStateChange(_ authState: AuthState) {
        Logger.debug("🔄 AuthViewModel: AuthState changed to: \(authState)")
        
        switch authState {
        case .loading:
            break // Managed by individual actions
        case .loggingOut:
            isLoading = true
            hideError()
        case .authenticated:
            isLoading = false
            hideError()
        case .unauthenticated:
            isLoading = false
            hideError()
            if !isShowingLogin {
                isShowingLogin = true
            }
        case .error(let message):
            isLoading = false
            showErrorMessage(message)
        }
    }
    
    func performAuthAction(
        canPerform: Bool,
        action: String,
        authCall: () async -> Result<User, Error>,
        onSuccess: (User) -> Void
    ) async {
        guard canPerform else {
            Logger.warning("⚠️ AuthViewModel: Cannot \(action) - validation failed")
            return
        }
        
        Logger.info("🔐 AuthViewModel: Starting \(action) process")
        isLoading = true
        hideError()
        
        let result = await authCall()
        
        switch result {
        case .success(let user):
            onSuccess(user)
        case .failure(let error):
            Logger.error("❌ AuthViewModel: \(action.capitalized) failed: \(error)")
            showErrorMessage(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func performAuthActionWithErrorHandling(
        action: String,
        authCall: () async -> Result<User, Error>,
        onSuccess: () -> Void
    ) async -> NetworkError? {
        Logger.info("🔐 AuthViewModel: \(action.capitalized) with error handling")
        isLoading = true
        hideError()
        
        let result = await authCall()
        
        switch result {
        case .success(let user):
            onSuccess()
            isLoading = false
            Logger.info("✅ \(action.capitalized) successful for user: \(user.displayName)")
            return nil
        case .failure(let error):
            isLoading = false
            Logger.error("❌ \(action.capitalized) failed: \(error)")
            return NetworkError.from(error)
        }
    }
    
    func createValidationError(_ message: String) -> NetworkError {
        return NetworkError.badRequest(APIError(
            message: message,
            code: "VALIDATION_ERROR",
            details: nil
        ))
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
    
    func clearLoginForm() {
        loginEmail = ""
        loginPassword = ""
    }
    
    func clearRegisterForm() {
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
