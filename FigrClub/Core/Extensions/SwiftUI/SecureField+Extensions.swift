//
//  SecureField+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import SwiftUI

// MARK: - Extensions for SecureField
extension SecureField {
    func textFieldStyle<S>(_ style: S) -> some View where S: TextFieldStyle {
        self.padding(.horizontal, AppTheme.Padding.large)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
            .themedFont(.bodyMedium)
    }
}
