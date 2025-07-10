//
//  FeedFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI

struct FeedFlowView: View {
    let user: User
    @EnvironmentObject private var coordinator: FeedCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Feed")
                    .font(.largeTitle.weight(.bold))
                
                Text("Bienvenido, \(user.username)!")
                    .font(.title2)
                
                // Botones de ejemplo para mostrar navegación con coordinator
                VStack(spacing: 12) {
                    Button("Ver Post de Ejemplo") {
                        coordinator.showPostDetail("post_123")
                    }
                    .buttonStyle(FigrButtonStyle())
                    
                    Button("Ver Perfil de Usuario") {
                        coordinator.showUserProfile("user_456")
                    }
                    .buttonStyle(FigrButtonStyle())
                    
                    Button("Cerrar Sesión") {
                        Task {
                            await authStateManager.logout()
                        }
                    }
                    .buttonStyle(FigrButtonStyle())
                }
                .padding()
            }
            .navigationTitle("FigrClub")
        }
        // Navegación usando sheets por ahora (se puede cambiar a NavigationStack después)
        .sheet(isPresented: $coordinator.showingPostDetail) {
            if let postId = coordinator.selectedPostId {
                NavigationView {
                    //PostDetailView(postId: postId, user: user)
                }
            }
        }
        .sheet(isPresented: $coordinator.showingUserProfile) {
            if let userId = coordinator.selectedUserId {
                NavigationView {
                    //UserProfileView(userId: userId, currentUser: user)
                }
            }
        }
        .sheet(isPresented: $coordinator.showingComments) {
            if let postId = coordinator.commentsPostId {
                NavigationView {
                    //CommentsView(postId: postId, user: user)
                }
            }
        }
    }
}
