//
//  SecondaryButtonStyle.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 1/8/25.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.figrButtonMedium)
            .foregroundColor(.figrTextPrimary)
            .padding(.horizontal, AppTheme.Padding.xLarge)
            .padding(.vertical, AppTheme.Padding.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(Color.figrSecondary.opacity(0.15))
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            )
            .animation(AppTheme.Animation.buttonTap, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
