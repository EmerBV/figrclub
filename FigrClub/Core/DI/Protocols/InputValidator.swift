//
//  InputValidator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

protocol InputValidatorProtocol {
    func validateEmail(_ email: String) -> Bool
    func validatePassword(_ password: String) -> Bool
    func validateUsername(_ username: String) -> Bool
}

final class InputValidator: InputValidatorProtocol {
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    func validateUsername(_ username: String) -> Bool {
        return username.count >= 3
    }
}
