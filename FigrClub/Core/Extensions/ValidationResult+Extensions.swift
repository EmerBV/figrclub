//
//  ValidationResult+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

enum ValidationResult {
    case valid
    case invalid(String)
}

extension ValidationResult {
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

extension ValidationResult: Equatable {
    static func == (lhs: ValidationResult, rhs: ValidationResult) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid):
            return true
        case (.invalid(let lhsMessage), .invalid(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
