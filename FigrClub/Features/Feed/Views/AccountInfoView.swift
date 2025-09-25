//
//  AccountInfoView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 25/9/25.
//

import SwiftUI

struct AccountInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        FigrNavigationStack {
            FigrVerticalScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Aquí puedes agregar el contenido de configuración cuando esté listo
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 60))
                            .themedTextColor(.secondary)
                        
                        Text("Sobre esta cuenta")
                            .font(.title.weight(.bold))
                            .themedTextColor(.primary)
                        
                        Text("Próximamente...")
                            .font(.body)
                            .themedTextColor(.secondary)
                    }
                    .padding(.top, AppTheme.Padding.xLarge)
                    
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Padding.large)
            }
            .navigationTitle("Sobre esta cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button {
                         dismiss()
                     } label: {
                         Image(systemName: "arrow.left")
                             .font(.title2)
                             .themedTextColor(.primary)
                     }
                 }
            }
            .navigationBarBackButtonHidden()
        }
    }
}

