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
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(email)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                
                Text(localizationManager.localizedString(for: .emailSentInstructions))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                Text(localizationManager.localizedString(for: .continueButton))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.tint)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }
}

// MARK: - Preview
#if DEBUG
struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        EmailVerificationView(
            email: "usuario@ejemplo.com",
            onContinue: {}
        )
    }
}
#endif 