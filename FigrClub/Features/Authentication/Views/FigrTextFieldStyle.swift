//
//  FigrTextFieldStyle.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct FigrTextFieldStyle: TextFieldStyle {
    let isValid: Bool?
    
    init(isValid: Bool? = nil) {
        self.isValid = isValid
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(AppConfig.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .font(.system(size: 16, weight: .regular))
    }
    
    private var borderColor: Color {
        guard let isValid = isValid else {
            return Color(.systemGray4)
        }
        return isValid ? .green : .red
    }
    
    private var borderWidth: CGFloat {
        isValid != nil ? 1.5 : 0.5
    }
}

// MARK: - Extensions for SecureField
extension SecureField {
    func textFieldStyle<S>(_ style: S) -> some View where S: TextFieldStyle {
        // SecureField wrapper que aplica el mismo estilo
        self.padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(AppConfig.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
            .font(.system(size: 16, weight: .regular))
    }
}
