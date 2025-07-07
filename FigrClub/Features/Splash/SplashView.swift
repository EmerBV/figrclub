//
//  SplashView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.large) {
                // Logo
                Image(systemName: "figure.socialdance")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.8)
                
                Text("FigrClub")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.blue)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                Text("Cargando...")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
}
