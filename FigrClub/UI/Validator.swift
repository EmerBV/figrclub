//
//  Validator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

struct Validator {
    static func validateEmail(_ email: String) -> ValidationState {
        if email.isEmpty {
            return .idle
        }
        
        if !email.isValidEmail {
            return .invalid("Formato de email inválido")
        }
        
        return .valid
    }
    
    static func validatePassword(_ password: String) -> ValidationState {
        if password.isEmpty {
            return .idle
        }
        
        if password.count < AppConfig.Validation.minPasswordLength {
            return .invalid("La contraseña debe tener al menos \(AppConfig.Validation.minPasswordLength) caracteres")
        }
        
        if password.count > AppConfig.Validation.maxPasswordLength {
            return .invalid("La contraseña no puede tener más de \(AppConfig.Validation.maxPasswordLength) caracteres")
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
    
    static func validateUsername(_ username: String) -> ValidationState {
        if username.isEmpty {
            return .idle
        }
        
        let trimmedUsername = username.trimmed
        
        if trimmedUsername.count < AppConfig.Validation.minUsernameLength {
            return .invalid("El nombre de usuario debe tener al menos \(AppConfig.Validation.minUsernameLength) caracteres")
        }
        
        if trimmedUsername.count > AppConfig.Validation.maxUsernameLength {
            return .invalid("El nombre de usuario no puede tener más de \(AppConfig.Validation.maxUsernameLength) caracteres")
        }
        
        if !trimmedUsername.isValidUsername {
            return .invalid("Solo se permiten letras, números, guiones y guiones bajos")
        }
        
        // Check if starts with letter or number
        if let firstChar = trimmedUsername.first, !firstChar.isLetter && !firstChar.isNumber {
            return .invalid("Debe comenzar con una letra o número")
        }
        
        return .valid
    }
    
    static func validateName(_ name: String) -> ValidationState {
        if name.isEmpty {
            return .idle
        }
        
        let trimmedName = name.trimmed
        
        if trimmedName.count < 2 {
            return .invalid("Debe tener al menos 2 caracteres")
        }
        
        if trimmedName.count > 50 {
            return .invalid("No puede tener más de 50 caracteres")
        }
        
        return .valid
    }
    
    static func validateConfirmPassword(password: String, confirmPassword: String) -> ValidationState {
        if confirmPassword.isEmpty {
            return .idle
        }
        
        if password != confirmPassword {
            return .invalid("Las contraseñas no coinciden")
        }
        
        return .valid
    }
}
