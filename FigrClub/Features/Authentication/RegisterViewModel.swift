//
//  RegisterViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var userType: UserType = .regular
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var registrationSuccess = false
    
    // MARK: - Legal Agreements
    @Published var acceptedTerms = false
    @Published var acceptedPrivacy = false
    @Published var acceptedMarketing = false
    
    // MARK: - Validation States
    @Published var firstNameValidationState: ValidationState = .idle
    @Published var lastNameValidationState: ValidationState = .idle
    @Published var emailValidationState: ValidationState = .idle
    @Published var usernameValidationState: ValidationState = .idle
    @Published var passwordValidationState: ValidationState = .idle
    @Published var confirmPasswordValidationState: ValidationState = .idle
    @Published var legalValidationState: ValidationState = .idle
    @Published var isFormValid = false
    
    // MARK: - Password Strength
    @Published var passwordStrength: PasswordStrength = .weak
    
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
    
    func register() async {
        guard isFormValid else {
            showErrorMessage("Por favor, corrige todos los errores en el formulario")
            return
        }
        
        isLoading = true
        hideError()
        
        let registerRequest = RegisterRequest(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            userType: userType,
            legalAcceptances: createLegalAcceptances(),
            consents: createConsents()
        )
        
        let result = await authManager.registerWithValidation(registerRequest)
        
        isLoading = false
        
        switch result {
        case .success:
            registrationSuccess = true
            clearForm()
        case .failure(let error):
            showErrorMessage(error.localizedDescription)
        }
    }
    
    func clearForm() {
        firstName = ""
        lastName = ""
        email = ""
        username = ""
        password = ""
        confirmPassword = ""
        acceptedTerms = false
        acceptedPrivacy = false
        acceptedMarketing = false
        hideError()
    }
    
    func hideError() {
        errorMessage = nil
        showError = false
    }
    
    func checkUsernameAvailability() async {
        guard !username.isEmpty && username.count >= 3 else { return }
        
        // TODO: Implement username availability check with API
        // This is a placeholder for the actual implementation
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // Simulate API call result
            if self?.username.lowercased() == "admin" || self?.username.lowercased() == "test" {
                self?.usernameValidationState = .invalid("Este nombre de usuario no está disponible")
            } else if self?.usernameValidationState != .invalid("") {
                self?.usernameValidationState = .valid
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupValidation() {
        // First Name validation
        $firstName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { name in
                self.validateFirstName(name)
            }
            .assign(to: &$firstNameValidationState)
        
        // Last Name validation
        $lastName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { name in
                self.validateLastName(name)
            }
            .assign(to: &$lastNameValidationState)
        
        // Email validation
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { email in
                self.validateEmail(email)
            }
            .assign(to: &$emailValidationState)
        
        // Username validation
        $username
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { username in
                self.validateUsername(username)
            }
            .assign(to: &$usernameValidationState)
        
        // Trigger username availability check
        $username
            .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.checkUsernameAvailability()
                }
            }
            .store(in: &cancellables)
        
        // Password validation and strength
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { password in
                let validation = self.validatePassword(password)
                let strength = self.calculatePasswordStrength(password)
                
                DispatchQueue.main.async {
                    self.passwordStrength = strength
                }
                
                return validation
            }
            .assign(to: &$passwordValidationState)
        
        // Confirm Password validation
        Publishers.CombineLatest($password, $confirmPassword)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { password, confirmPassword in
                self.validateConfirmPassword(password: password, confirmPassword: confirmPassword)
            }
            .assign(to: &$confirmPasswordValidationState)
        
        // Legal validation
        Publishers.CombineLatest($acceptedTerms, $acceptedPrivacy)
            .map { terms, privacy in
                self.validateLegalAcceptances(terms: terms, privacy: privacy)
            }
            .assign(to: &$legalValidationState)
        
        // Form validation
        let allValidations = Publishers.CombineLatest4(
            Publishers.CombineLatest($firstNameValidationState, $lastNameValidationState),
            Publishers.CombineLatest($emailValidationState, $usernameValidationState),
            Publishers.CombineLatest($passwordValidationState, $confirmPasswordValidationState),
            $legalValidationState
        )
        
        allValidations
            .map { nameValidations, contactValidations, passwordValidations, legalValidation in
                let (firstName, lastName) = nameValidations
                let (email, username) = contactValidations
                let (password, confirmPassword) = passwordValidations
                
                return firstName.isValid &&
                       lastName.isValid &&
                       email.isValid &&
                       username.isValid &&
                       password.isValid &&
                       confirmPassword.isValid &&
                       legalValidation.isValid
            }
            .assign(to: &$isFormValid)
    }
    
    private func setupAuthStateObserver() {
        authManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isLoading = self?.authManager.isLoading ?? false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validateFirstName(_ name: String) -> ValidationState {
        if name.isEmpty {
            return .idle
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.count < 2 {
            return .invalid("El nombre debe tener al menos 2 caracteres")
        }
        
        if trimmedName.count > 50 {
            return .invalid("El nombre no puede tener más de 50 caracteres")
        }
        
        return .valid
    }
    
    private func validateLastName(_ name: String) -> ValidationState {
        if name.isEmpty {
            return .idle
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.count < 2 {
            return .invalid("El apellido debe tener al menos 2 caracteres")
        }
        
        if trimmedName.count > 50 {
            return .invalid("El apellido no puede tener más de 50 caracteres")
        }
        
        return .valid
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
    
    private func validateUsername(_ username: String) -> ValidationState {
        if username.isEmpty {
            return .idle
        }
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedUsername.count < 3 {
            return .invalid("El nombre de usuario debe tener al menos 3 caracteres")
        }
        
        if trimmedUsername.count > 30 {
            return .invalid("El nombre de usuario no puede tener más de 30 caracteres")
        }
        
        // Check for valid characters (alphanumeric, underscore, dash)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        if trimmedUsername.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .invalid("Solo se permiten letras, números, guiones y guiones bajos")
        }
        
        // Check if starts with letter or number
        if let firstChar = trimmedUsername.first, !firstChar.isLetter && !firstChar.isNumber {
            return .invalid("Debe comenzar con una letra o número")
        }
        
        return .valid
    }
    
    private func validatePassword(_ password: String) -> ValidationState {
        if password.isEmpty {
            return .idle
        }
        
        if password.count < 8 {
            return .invalid("La contraseña debe tener al menos 8 caracteres")
        }
        
        if password.count > 128 {
            return .invalid("La contraseña no puede tener más de 128 caracteres")
        }
        
        // Check for at least one uppercase letter
        if !password.contains(where: { $0.isUppercase }) {
            return .invalid("Debe contener al menos una letra mayúscula")
        }
        
        // Check for at least one lowercase letter
        if !password.contains(where: { $0.isLowercase }) {
            return .invalid("Debe contener al menos una letra minúscula")
        }
        
        // Check for at least one number
        if !password.contains(where: { $0.isNumber }) {
            return .invalid("Debe contener al menos un número")
        }
        
        return .valid
    }
    
    private func validateConfirmPassword(password: String, confirmPassword: String) -> ValidationState {
        if confirmPassword.isEmpty {
            return .idle
        }
        
        if password != confirmPassword {
            return .invalid("Las contraseñas no coinciden")
        }
        
        return .valid
    }
    
    private func validateLegalAcceptances(terms: Bool, privacy: Bool) -> ValidationState {
        if !terms {
            return .invalid("Debes aceptar los términos de servicio")
        }
        
        if !privacy {
            return .invalid("Debes aceptar la política de privacidad")
        }
        
        return .valid
    }
    
    // MARK: - Password Strength Calculation
    
    private func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        
        // Character types
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) { score += 1 }
        
        // Common patterns (reduce score)
        if password.lowercased().contains("password") ||
           password.lowercased().contains("123456") ||
           password.lowercased().contains("qwerty") {
            score -= 2
        }
        
        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        case 5...6:
            return .strong
        default:
            return .veryStrong
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLegalAcceptances() -> [LegalAcceptance] {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        var acceptances: [LegalAcceptance] = []
        
        if acceptedTerms {
            acceptances.append(LegalAcceptance(documentType: "TERMS_OF_SERVICE", acceptedAt: timestamp))
        }
        
        if acceptedPrivacy {
            acceptances.append(LegalAcceptance(documentType: "PRIVACY_POLICY", acceptedAt: timestamp))
        }
        
        return acceptances
    }
    
    private func createConsents() -> [Consent] {
        return [
            Consent(consentType: "MARKETING_EMAILS", isGranted: acceptedMarketing)
        ]
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

// MARK: - Password Strength
enum PasswordStrength: CaseIterable {
    case weak
    case medium
    case strong
    case veryStrong
    
    var description: String {
        switch self {
        case .weak:
            return "Débil"
        case .medium:
            return "Media"
        case .strong:
            return "Fuerte"
        case .veryStrong:
            return "Muy Fuerte"
        }
    }
    
    var color: String {
        switch self {
        case .weak:
            return "red"
        case .medium:
            return "orange"
        case .strong:
            return "yellow"
        case .veryStrong:
            return "green"
        }
    }
    
    var progress: Double {
        switch self {
        case .weak:
            return 0.25
        case .medium:
            return 0.5
        case .strong:
            return 0.75
        case .veryStrong:
            return 1.0
        }
    }
}
