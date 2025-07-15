//
//  EBVPrimaryBtnStyle.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct EBVPrimaryBtnStyle: ButtonStyle {
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.callout.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(
                isEnabled ? Color.blue : Color.gray
            )
            .cornerRadius(AppConfig.UI.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(!isEnabled || isLoading)
    }
}
