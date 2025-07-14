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

/*
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
 */

struct AuthTextFieldStyle: TextFieldStyle {
    let isValid: Bool
    
    init(isValid: Bool = true) {
        self.isValid = isValid
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .font(.system(size: 16, weight: .regular))
    }
    
    private var borderColor: Color {
        if !isValid {
            return .red
        }
        return Color(.systemGray4)
    }
    
    private var borderWidth: CGFloat {
        !isValid ? 1.5 : 0.5
    }
}
