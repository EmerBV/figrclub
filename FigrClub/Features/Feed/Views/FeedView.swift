//
//  FeedView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import SwiftUI

// MARK: - Feed View
struct FeedView: View {
    @StateObject private var viewModel = DependencyContainer.shared.resolve(FeedViewModel.self)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    // FIX: Debug header en modo Debug
#if DEBUG
                    debugHeader
#endif
                    
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        LoadingView(message: "Cargando posts...")
                    } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            title: "No hay posts",
                            message: "Sé el primero en compartir algo increíble",
                            imageName: "doc.text",
                            buttonTitle: "Crear Post"
                        ) {
                            // Handle create post
                        }
                    } else {
                        // FIX: Mejorar el rendering de posts
                        ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                            PostCardView(post: post)
                                .onAppear {
#if DEBUG
                                    print("📱 Post \(index) appeared: ID \(post.id)")
#endif
                                    
                                    // FIX: Verificar correctamente si es el último post
                                    if index == viewModel.posts.count - 1 && !viewModel.isLoadingMore {
#if DEBUG
                                        print("🔄 Triggering load more for post \(index)")
#endif
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                                }
                        }
                        
                        // FIX: Indicador de carga más visible
                        if viewModel.isLoadingMore {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Cargando más posts...")
                                    .font(.figrCaption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
#if DEBUG
                print("🔄 Manual refresh triggered")
#endif
                await viewModel.refreshPosts()
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            // FIX: Toolbar con botón de debug
            .toolbar {
#if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        viewModel.debugPostsState()
                    }
                    .font(.caption)
                }
#endif
            }
        }
        .task {
#if DEBUG
            print("📱 FeedView appeared, loading posts...")
#endif
            await viewModel.loadPosts()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "FeedView")
        }
        // FIX: Error handling mejorado
        .alert("Error", isPresented: $viewModel.showError) {
            Button("Reintentar") {
                Task {
                    await viewModel.loadPosts()
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Ha ocurrido un error")
        }
    }
    
    // MARK: - Debug Views
#if DEBUG
    private var debugHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🐛 DEBUG INFO")
                .font(.figrCaption.bold())
                .foregroundColor(.red)
            
            Text("Posts: \(viewModel.posts.count) | Loading: \(viewModel.isLoading ? "✅" : "❌") | Loading More: \(viewModel.isLoadingMore ? "✅" : "❌")")
                .font(.figrCaption2)
                .foregroundColor(.secondary)
            
            if !viewModel.posts.isEmpty {
                Text("IDs: \(viewModel.posts.prefix(5).map { String($0.id) }.joined(separator: ", "))")
                    .font(.figrCaption2)
                    .foregroundColor(.blue)
            }
            
            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .font(.figrCaption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
#endif
}

// MARK: - Preview
#Preview {
    FeedView()
        .dependencyInjection()
}
