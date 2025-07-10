//
//  ProfileFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI

struct ProfileFlowView: View {
    let user: User
    @EnvironmentObject private var coordinator: ProfileCoordinator
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                Text("Perfil")
                    .font(.largeTitle.weight(.bold))
                
                VStack(spacing: Spacing.small) {
                    Text(user.username)
                        .font(.title2.weight(.semibold))
                    
                    Text(user.fullName) // Actualizado: ya no es opcional en el nuevo model
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Text(user.email)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationTitle("Perfil")
        }
    }
}
