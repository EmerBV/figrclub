//
//  ProfileOptionRow.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 24/9/25.
//

import SwiftUI

struct ProfileOptionRow<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination?
    let action: (() -> Void)?
    
    @Environment(\.localizationManager) private var localizationManager
    
    // Inicializador para NavigationLink
    init(icon: String, title: String, destination: Destination) {
        self.icon = icon
        self.title = title
        self.destination = destination
        self.action = nil
    }
    
    // Inicializador para Button action
    init(icon: String, title: String, action: @escaping () -> Void) where Destination == Never {
        self.icon = icon
        self.title = title
        self.destination = nil
        self.action = action
    }
    
    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    rowContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: action ?? {}) {
                    rowContent
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .themedTextColor(.primary)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
                .themedTextColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .themedTextColor(.secondary)
        }
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.vertical, AppTheme.Padding.medium)
    }
}

