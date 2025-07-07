//
//  ValidationService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol ValidationServiceProtocol {
    func validateEmail(_ email: String) -> ValidationResult
    func validatePassword(_ password: String) -> ValidationResult
    func validateUsername(_ username: String) -> ValidationResult
    func validateFullName(_ fullName: String) -> ValidationResult
}

final class ValidationService: ValidationServiceProtocol {
    
    func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isEmpty else {
            return .invalid("El email no puede estar vacío")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return .invalid("Formato de email inválido")
        }
        
        return .valid
    }
    
    func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .invalid("La contraseña no puede estar vacía")
        }
        
        guard password.count >= 8 else {
            return .invalid("La contraseña debe tener al menos 8 caracteres")
        }
        
        // Check for at least one letter and one number
        let letterRegex = ".*[A-Za-z]+.*"
        let numberRegex = ".*[0-9]+.*"
        
        guard NSPredicate(format:"SELF MATCHES %@", letterRegex).evaluate(with: password) else {
            return .invalid("La contraseña debe contener al menos una letra")
        }
        
        guard NSPredicate(format:"SELF MATCHES %@", numberRegex).evaluate(with: password) else {
            return .invalid("La contraseña debe contener al menos un número")
        }
        
        return .valid
    }
    
    func validateUsername(_ username: String) -> ValidationResult {
        guard !username.isEmpty else {
            return .invalid("El nombre de usuario no puede estar vacío")
        }
        
        guard username.count >= 3 else {
            return .invalid("El nombre de usuario debe tener al menos 3 caracteres")
        }
        
        guard username.count <= 20 else {
            return .invalid("El nombre de usuario no puede tener más de 20 caracteres")
        }
        
        // Allow letters, numbers, and underscores only
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        
        guard usernamePredicate.evaluate(with: username) else {
            return .invalid("El nombre de usuario solo puede contener letras, números y guiones bajos")
        }
        
        return .valid
    }
    
    func validateFullName(_ fullName: String) -> ValidationResult {
        guard !fullName.isEmpty else {
            return .invalid("El nombre completo no puede estar vacío")
        }
        
        guard fullName.count >= 2 else {
            return .invalid("El nombre completo debe tener al menos 2 caracteres")
        }
        
        guard fullName.count <= 50 else {
            return .invalid("El nombre completo no puede tener más de 50 caracteres")
        }
        
        return .valid
    }
}

enum ValidationResult {
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
