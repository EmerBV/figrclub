//
//  EBVTextFieldStyle.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct EBVTextFieldStyle: TextFieldStyle {
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
