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
        self.padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
            .font(.system(size: 16, weight: .regular))
    }
}
