//
//  ErrorView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title.weight(.bold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.large)
            
            Button("Reintentar") {
                retry()
            }
            .buttonStyle(FigrButtonStyle())
            .padding(.horizontal, Spacing.large)
        }
        .padding(Spacing.large)
    }
}
