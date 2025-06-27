//
//  LoginViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Validation States
    @Published var emailValidationState: ValidationState = .idle
    @Published var passwordValidationState: ValidationState = .idle
    @Published var isFormValid = false
    
    // MARK: - Private Properties
    private let authManager: AuthManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(authManager: AuthManagerProtocol = DependencyContainer.shared.resolve(AuthManager.self)) {
        self.authManager = authManager
        setupValidation()
        setupAuthStateObserver()
    }
    
    // MARK: - Public Methods
    
    func login() async {
        guard isFormValid else {
            showErrorMessage("Por favor, corrige los errores en el formulario")
            return
        }
        
        isLoading = true
        hideError()
        
        let result = await authManager.loginWithValidation(email: email, password: password)
        
        isLoading = false
        
        switch result {
        case .success:
            // Success is handled by AuthManager state changes
            clearForm()
        case .failure(let error):
            showErrorMessage(error.localizedDescription)
        }
    }
    
    func forgotPassword() {
        // TODO: Implement forgot password flow
        print("Forgot password tapped for email: \(email)")
    }
    
    func clearForm() {
        email = ""
        password = ""
        hideError()
    }
    
    func hideError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Private Methods
    
    private func setupValidation() {
        // Email validation
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { email in
                self.validateEmail(email)
            }
            .assign(to: &$emailValidationState)
        
        // Password validation
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { password in
                self.validatePassword(password)
            }
            .assign(to: &$passwordValidationState)
        
        // Form validation
        Publishers.CombineLatest($emailValidationState, $passwordValidationState)
            .map { emailState, passwordState in
                emailState == .valid && passwordState == .valid
            }
            .assign(to: &$isFormValid)
    }
    
    private func setupAuthStateObserver() {
        // Observe auth manager loading state
        authManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isLoading = self?.authManager.isLoading ?? false
            }
            .store(in: &cancellables)
    }
    
    private func validateEmail(_ email: String) -> ValidationState {
        if email.isEmpty {
            return .idle
        }
        
        if !email.isValidEmail {
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
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.hideError()
        }
    }
}

// MARK: - Validation State
enum ValidationState: Equatable {
    case idle
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
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
