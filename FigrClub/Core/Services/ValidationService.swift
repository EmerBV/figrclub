//
//  ValidationService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

// MARK: - Validation State
enum ValidationState {
    case idle, valid, invalid
}

// MARK: - Validation Result
enum ValidationResult: Equatable {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Field State (para UI)
enum FieldState: Equatable {
    case normal
    case valid
    case invalid(String)
}

// MARK: - Validation Service
protocol ValidationServiceProtocol: Sendable {
    func validateEmail(_ email: String) -> ValidationResult
    func validatePassword(_ password: String) -> ValidationResult
    func validateUsername(_ username: String) -> ValidationResult
    func validateFullName(_ fullName: String) -> ValidationResult
}

final class ValidationService: ValidationServiceProtocol {
    
    private nonisolated let localizationManager: LocalizationManagerProtocol
    
    init(localizationManager: LocalizationManagerProtocol) {
        self.localizationManager = localizationManager
    }
    
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            return .invalid(localizationManager.localizedString(for: .emailRequired))
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            return .invalid(localizationManager.localizedString(for: .emailInvalid))
        }
        
        return .valid
    }
    
    func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .invalid(localizationManager.localizedString(for: .passwordRequired))
        }
        
        guard password.count >= 8 else {
            return .invalid(localizationManager.localizedString(for: .passwordTooShort))
        }
        
        guard password.count <= 128 else {
            return .invalid(localizationManager.localizedString(for: .passwordTooLong))
        }
        
        // Check for at least one letter
        let letterRegex = ".*[A-Za-z]+.*"
        let hasLetter = NSPredicate(format:"SELF MATCHES %@", letterRegex).evaluate(with: password)
        
        guard hasLetter else {
            return .invalid(localizationManager.localizedString(for: .passwordMustContainLetter))
        }
        
        // Check for at least one number
        let numberRegex = ".*[0-9]+.*"
        let hasNumber = NSPredicate(format:"SELF MATCHES %@", numberRegex).evaluate(with: password)
        
        guard hasNumber else {
            return .invalid(localizationManager.localizedString(for: .passwordMustContainNumber))
        }
        
        // Check for at least one special character (common requirement for secure passwords)
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
        let hasSpecialChar = NSPredicate(format:"SELF MATCHES %@", specialCharRegex).evaluate(with: password)
        
        guard hasSpecialChar else {
            return .invalid(localizationManager.localizedString(for: .passwordMustContainSpecialChar))
        }
        
        // Check for no spaces (common security requirement)
        guard !password.contains(" ") else {
            return .invalid(localizationManager.localizedString(for: .passwordNoSpaces))
        }
        
        return .valid
    }
    
    func validateUsername(_ username: String) -> ValidationResult {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUsername.isEmpty else {
            return .invalid(localizationManager.localizedString(for: .usernameRequired))
        }
        
        guard trimmedUsername.count >= 3 else {
            return .invalid(localizationManager.localizedString(for: .usernameTooShort))
        }
        
        guard trimmedUsername.count <= 20 else {
            return .invalid(localizationManager.localizedString(for: .usernameTooLong))
        }
        
        // Only allow alphanumeric characters and underscores
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        
        guard usernamePredicate.evaluate(with: trimmedUsername) else {
            return .invalid(localizationManager.localizedString(for: .usernameInvalidChars))
        }
        
        return .valid
    }
    
    func validateFullName(_ fullName: String) -> ValidationResult {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .invalid(localizationManager.localizedString(for: .fullNameRequired))
        }
        
        guard trimmedName.count >= 2 else {
            return .invalid(localizationManager.localizedString(for: .fullNameTooShort))
        }
        
        guard trimmedName.count <= 50 else {
            return .invalid(localizationManager.localizedString(for: .fullNameTooLong))
        }
        
        // Allow letters, spaces, and some special characters for international names
        let nameRegex = "^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\\s'.-]+$"
        let namePredicate = NSPredicate(format:"SELF MATCHES %@", nameRegex)
        
        guard namePredicate.evaluate(with: trimmedName) else {
            return .invalid(localizationManager.localizedString(for: .fullNameInvalidChars))
        }
        
        return .valid
    }
}

// MARK: - Debug Extension (for testing purposes)
#if DEBUG
extension ValidationService {
    static func testPasswordValidation() {
        let service = ValidationService()
        let testPasswords = [
            "12345678", // Solo números, falta letra y carácter especial
            "password", // Solo letras, falta número y carácter especial  
            "password123", // Letra y número, falta carácter especial
            "Password123!", // Válido: letra, número y carácter especial
            "MyP@ssw0rd", // Válido: letra, número y carácter especial
            "short!", // Muy corto
            "password with spaces!", // Con espacios
            "", // Vacío
        ]
        
        print("🧪 Testing password validation:")
        for password in testPasswords {
            let result = service.validatePassword(password)
            let status = result.isValid ? "✅ VALID" : "❌ INVALID"
            let message = result.errorMessage ?? "No errors"
            print("\(status): '\(password)' - \(message)")
        }
    }
}
#endif
