//
//  PrimaryButtonStyle.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .figrButtonText))
            }
            
            configuration.label
        }
        .font(.figrButtonMedium)
        .foregroundColor(isEnabled ? .figrButtonText : .figrButtonText.opacity(0.6))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.xLarge)
        .padding(.vertical, AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                .fill(backgroundFill)
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
        )
        .shadow(
            color: isEnabled ? AppTheme.Shadow.buttonShadowColor : .clear,
            radius: configuration.isPressed ? 2 : AppTheme.Shadow.buttonShadow.radius,
            x: AppTheme.Shadow.buttonShadow.x,
            y: configuration.isPressed ? 1 : AppTheme.Shadow.buttonShadow.y
        )
        .animation(AppTheme.Animation.buttonTap, value: configuration.isPressed)
        .disabled(!isEnabled || isLoading)
    }
    
    private var backgroundFill: Color {
        if !isEnabled {
            return .figrButtonDisabled
        }
        return .figrPrimary
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
    
    static func primary(isEnabled: Bool = true, isLoading: Bool = false) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isEnabled: isEnabled, isLoading: isLoading)
    }
}
