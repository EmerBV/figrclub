//
//  OutlineButtonStyle.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 1/8/25.
//

import SwiftUI

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.figrButtonMedium)
            .foregroundColor(.figrPrimary)
            .padding(.horizontal, AppTheme.Padding.xLarge)
            .padding(.vertical, AppTheme.Padding.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(Color.figrPrimary, lineWidth: 1.5)
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            )
            .animation(AppTheme.Animation.buttonTap, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == OutlineButtonStyle {
    static var outline: OutlineButtonStyle { OutlineButtonStyle() }
}
