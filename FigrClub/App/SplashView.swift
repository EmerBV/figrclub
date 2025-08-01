//
//  SplashView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var progress: Double = 0.0
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        ZStack {
            // Fondo degradado
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo/Icono de la app
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .fill(Color.clear)
                                    .frame(width: 100, height: 100)
                            )
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                    }
                    
                    // Título de la app
                    Text("FigrClub")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color.figrPrimary)
                        .opacity(isAnimating ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Indicador de carga
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text(localizationManager.localizedString(for: .loading))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                
                Spacer()
                    .frame(height: 50)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
#endif
