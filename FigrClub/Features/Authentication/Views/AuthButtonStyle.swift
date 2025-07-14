//
//  AuthButtonStyle.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI

struct AuthButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(buttonColor)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(!isEnabled || isLoading)
    }
    
    private var buttonColor: Color {
        if !isEnabled || isLoading {
            return Color.gray.opacity(0.6)
        }
        return Color.black
    }
}
