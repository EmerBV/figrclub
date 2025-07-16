//
//  MarketplaceFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI
import Kingfisher

struct MarketplaceFlowView: View {
    let user: User
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Banner del marketplace
                    KFImage(URL(string: "https://picsum.photos/seed/marketplace/800/200"))
                        .bannerImageStyle(height: 200)
                        .overlay(
                            VStack {
                                Text("Marketplace FigrClub")
                                    .font(.title.weight(.bold))
                                    .foregroundColor(.white)
                                
                                Text("Compra y vende figuras únicas")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        )
                    
                    // Grid de productos de ejemplo
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(0..<8) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                // Imagen del producto
                                KFImage(URL(string: "https://picsum.photos/seed/product\(index)/300/300"))
                                    .thumbnailStyle(size: 120)
                                    .onTapGesture {
                                        Logger.info("🛍️ Product \(index) tapped")
                                    }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Figura \(index + 1)")
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text("$\((index + 1) * 25).00")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.blue)
                                    
                                    HStack(spacing: 4) {
                                        KFImage(URL(string: "https://picsum.photos/seed/seller\(index)/100/100"))
                                            .profileImageStyle(size: 20)
                                        
                                        Text("Vendedor \(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("¡Próximamente!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Aquí podrás comprar y vender figuras")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("Marketplace")
        }
    }
}
