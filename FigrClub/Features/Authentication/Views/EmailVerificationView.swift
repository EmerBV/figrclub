//
//  EmailVerificationView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import SwiftUI

struct EmailVerificationView: View {
    let email: String
    let onContinue: () -> Void
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                // Icon
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                
                // Title
                Text(localizationManager.localizedString(for: .verifyEmail))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // Message
            VStack(spacing: 16) {
                Text(localizationManager.localizedString(for: .emailSentMessage))
                    .font(.body)
                    .themedTextColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(email)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor(.primary)
                    .padding(.horizontal, AppTheme.Padding.large)
                    .padding(.vertical, AppTheme.Padding.small)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(Color(.systemGray6))
                    )
                
                Text(localizationManager.localizedString(for: .emailSentInstructions))
                    .font(.body)
                    .themedTextColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                Text(localizationManager.localizedString(for: .continueButton))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Padding.large)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(.tint)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Padding.xLarge)
        .padding(.vertical, AppTheme.Padding.xxLarge)
    }
}

