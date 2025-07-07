//
//  AuthTabButton.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct AuthTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundColor(isSelected ? .white : .blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.small)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(AppConfig.UI.cornerRadius)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
