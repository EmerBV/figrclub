//
//  CreatePostView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import SwiftUI

// MARK: - Create Post View
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DependencyContainer.shared.resolve(CreatePostViewModel.self)
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                // Content Input
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("¿Qué quieres compartir?")
                        .font(.figrHeadline)
                        .foregroundColor(.figrTextPrimary)
                    
                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 150)
                        .padding()
                        .background(Color.figrSurface)
                        .cornerRadius(CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(Color.figrBorder, lineWidth: 1)
                        )
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: Spacing.medium) {
                    FigrButton(
                        title: "Publicar",
                        isLoading: viewModel.isPosting,
                        isEnabled: !viewModel.content.isEmpty
                    ) {
                        Task {
                            await viewModel.createPost()
                            if viewModel.postCreated {
                                dismiss()
                            }
                        }
                    }
                    
                    FigrButton(title: "Cancelar", style: .ghost) {
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationTitle("Crear Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "CreatePostView")
        }
    }
}
