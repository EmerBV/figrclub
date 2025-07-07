//
//  AuthTextField.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

enum ValidationState {
    case idle, valid, invalid
}

struct AuthTextField: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var validationState: ValidationState = .idle
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(AuthTextFieldStyle(validationState: validationState))
            .keyboardType(keyboardType)
    }
}

struct AuthSecureField: View {
    @Binding var text: String
    let placeholder: String
    var validationState: ValidationState = .idle
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .textFieldStyle(AuthTextFieldStyle(validationState: validationState))
    }
}

struct AuthTextFieldStyle: TextFieldStyle {
    let validationState: ValidationState
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Color(.systemGray6))
            .cornerRadius(AppConfig.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    private var borderColor: Color {
        switch validationState {
        case .valid:
            return .green
        case .invalid:
            return .red
        case .idle:
            return .clear
        }
    }
}
