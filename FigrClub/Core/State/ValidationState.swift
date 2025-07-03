//
//  ValidationState.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import Foundation

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
    
    var isInvalid: Bool {
        if case .invalid = self {
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
    
    static func == (lhs: ValidationState, rhs: ValidationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.valid, .valid):
            return true
        case let (.invalid(message1), .invalid(message2)):
            return message1 == message2
        default:
            return false
        }
    }
}

// MARK: - Password Strength
enum PasswordStrength: Int, CaseIterable {
    case weak = 0
    case fair = 1
    case good = 2
    case strong = 3
    
    var description: String {
        switch self {
        case .weak:
            return "Débil"
        case .fair:
            return "Regular"
        case .good:
            return "Buena"
        case .strong:
            return "Fuerte"
        }
    }
    
    var color: String {
        switch self {
        case .weak:
            return "figrError"
        case .fair:
            return "figrWarning"
        case .good:
            return "figrInfo"
        case .strong:
            return "figrSuccess"
        }
    }
    
    static func calculate(for password: String) -> PasswordStrength {
        var strength = 0
        
        if password.count >= 8 { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        if password.rangeOfCharacter(from: specialCharacters) != nil { strength += 1 }
        
        switch strength {
        case 0...2:
            return .weak
        case 3...4:
            return .fair
        case 5:
            return .good
        default:
            return .strong
        }
    }
}
