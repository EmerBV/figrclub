//
//  CreateFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI

struct CreateFlowView: View {
    let user: User
    @EnvironmentObject private var coordinator: CreateCoordinator
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                Text("Crear")
                    .font(.largeTitle.weight(.bold))
                
                Text("¡Próximamente!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Aquí podrás crear posts y publicar figuras")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .navigationTitle("Crear")
            .padding()
        }
    }
}
