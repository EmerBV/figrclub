//
//  ImageLoadingPlaceholder.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 8/8/25.
//

import SwiftUI

struct ImageLoadingPlaceholder: View {
    let aspectRatio: CGFloat?
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Fondo base
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
            
            // Contenido del placeholder
            VStack(spacing: 12) {
                // ProgressView animado
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .figrBlueAccent))
                    .scaleEffect(1.2)
                
                // Texto
                Text("Cargando imagen...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(isAnimating ? 0.5 : 1.0)
            }
            
            // Shimmer effect
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: isAnimating ? 300 : -300)
                .animation(
                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .aspectRatio(aspectRatio ?? 1, contentMode: .fit)
        .onAppear {
            isAnimating = true
        }
    }
}
