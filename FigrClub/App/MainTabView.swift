//
//  MainTabView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

struct MainTabView: View {
    let user: User
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    var body: some View {
        TabView {
            // Feed
            NavigationView {
                VStack {
                    Text("Feed")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Bienvenido, \(user.username)!")
                        .font(.title2)
                    
                    Button("Cerrar Sesión") {
                        Task {
                            await authStateManager.logout()
                        }
                    }
                    .buttonStyle(FigrButtonStyle())
                    .padding()
                }
                .navigationTitle("FigrClub")
            }
            .tabItem {
                Image(systemName: "house")
                Text("Feed")
            }
            
            // Marketplace
            NavigationView {
                Text("Marketplace")
                    .navigationTitle("Marketplace")
            }
            .tabItem {
                Image(systemName: "cart")
                Text("Marketplace")
            }
            
            // Create
            NavigationView {
                Text("Crear Post")
                    .navigationTitle("Crear")
            }
            .tabItem {
                Image(systemName: "plus.circle")
                Text("Crear")
            }
            
            // Notifications
            NavigationView {
                Text("Notificaciones")
                    .navigationTitle("Notificaciones")
            }
            .tabItem {
                Image(systemName: "bell")
                Text("Notificaciones")
            }
            
            // Profile
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
            .tabItem {
                Image(systemName: "person")
                Text("Perfil")
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUser = User(
            id: 1,
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            username: "johndoe",
            userType: "REGULAR",
            subscriptionType: "FREE",
            isVerified: true,
            profileImageUrl: nil,
            bio: "Sample user bio",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        MainTabView(user: sampleUser)
            .environmentObject(DependencyInjector.shared.resolve(AuthStateManager.self))
    }
}
#endif

