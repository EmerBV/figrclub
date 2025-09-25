//
//  PostOptionRow.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 25/9/25.
//

import SwiftUI

struct PostOptionRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool
    let destination: Destination?
    let action: (() -> Void)?
    
    @Environment(\.localizationManager) private var localizationManager
    
    // Inicializador para NavigationLink
    init(icon: String, title: String, subtitle: String, isDestructive: Bool = false, destination: Destination) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.destination = destination
        self.action = nil
    }
    
    // Inicializador para Button action
    init(icon: String, title: String, subtitle: String, isDestructive: Bool = false, action: @escaping () -> Void) where Destination == Never {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
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
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isDestructive ? .red : .primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .themedTextColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, AppTheme.Padding.large)
    }
    
    /*
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .themedTextColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, AppTheme.Padding.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
     */
}
