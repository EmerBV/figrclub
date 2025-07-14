//
//  MarketplaceFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI

struct MarketplaceFlowView: View {
    let user: User
    @EnvironmentObject private var coordinator: MarketplaceCoordinator
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                Text("Marketplace")
                    .font(.largeTitle.weight(.bold))
                
                Text("¡Próximamente!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Aquí podrás comprar y vender figuras")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .navigationTitle("Marketplace")
            .padding()
        }
    }
}
