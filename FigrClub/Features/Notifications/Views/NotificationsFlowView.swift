//
//  NotificationsFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI

struct NotificationsFlowView: View {
    let user: User
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                Text("Notificaciones")
                    .font(.largeTitle.weight(.bold))
                
                Text("¡Próximamente!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Aquí verás todas tus notificaciones")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .navigationTitle("Notificaciones")
            .padding()
        }
    }
}
