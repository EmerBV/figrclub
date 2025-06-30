//
//  ValidationState.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

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

enum PasswordStrength: CaseIterable {
    case weak
    case medium
    case strong
    case veryStrong
    
    var description: String {
        switch self {
        case .weak: return "Débil"
        case .medium: return "Media"
        case .strong: return "Fuerte"
        case .veryStrong: return "Muy Fuerte"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .figrError
        case .medium: return .figrWarning
        case .strong: return .yellow
        case .veryStrong: return .figrSuccess
        }
    }
    
    var progress: Double {
        switch self {
        case .weak: return 0.25
        case .medium: return 0.5
        case .strong: return 0.75
        case .veryStrong: return 1.0
        }
    }
}
