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
                    // Debug header en modo Debug
#if DEBUG
                    debugHeader
#endif
                    
                    // ✅ Corrección: Usar 'items' en lugar de 'posts'
                    if viewModel.isLoading && viewModel.items.isEmpty {
                        LoadingView(message: "Cargando posts...")
                    } else if viewModel.items.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            title: "No hay posts",
                            message: "Sé el primero en compartir algo increíble",
                            imageName: "doc.text",
                            buttonTitle: "Crear Post"
                        ) {
                            // Handle create post
                        }
                    } else {
                        // ✅ Corrección: Usar 'items' y agregar closure para like
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, post in
                            PostCardView(
                                post: post,
                                onLikeToggle: { post in
                                    viewModel.toggleLike(for: post) // ✅ Delegar al ViewModel
                                }
                            )
                            .onAppear {
#if DEBUG
                                print("📱 Post \(index) appeared: ID \(post.id)")
#endif
                                
                                // ✅ Corrección: Verificar si es el último post y usar loadMore()
                                if index == viewModel.items.count - 1 && !viewModel.isLoadingMore {
#if DEBUG
                                    print("🔄 Triggering load more for post \(index)")
#endif
                                    Task {
                                        await viewModel.loadMore() // ✅ Método correcto de PaginatedViewModel
                                    }
                                }
                            }
                        }
                        
                        // Indicador de carga más visible
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
                // ✅ Corrección: Usar refresh() de PaginatedViewModel
                await viewModel.refresh()
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
#if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        debugPostsState() // ✅ Método local de debug
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
            // ✅ Corrección: Usar refresh() en lugar de loadPosts()
            await viewModel.refresh()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "FeedView")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("Reintentar") {
                Task {
                    await viewModel.refresh() // ✅ Método correcto
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Ha ocurrido un error")
        }
    }
    
    // MARK: - Debug Methods
#if DEBUG
    private var debugHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🐛 DEBUG INFO")
                .font(.figrCaption.bold())
                .foregroundColor(.red)
            
            // ✅ Corrección: Usar 'items' en lugar de 'posts'
            Text("Posts: \(viewModel.items.count) | Loading: \(viewModel.isLoading ? "✅" : "❌") | Loading More: \(viewModel.isLoadingMore ? "✅" : "❌")")
                .font(.figrCaption2)
                .foregroundColor(.secondary)
            
            if !viewModel.items.isEmpty {
                Text("IDs: \(viewModel.items.prefix(5).map { String($0.id) }.joined(separator: ", "))")
                    .font(.figrCaption2)
                    .foregroundColor(.blue)
            }
            
            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .font(.figrCaption2)
                    .foregroundColor(.red)
            }
            
            // ✅ Información adicional de paginación
            Text("Page: \(viewModel.currentPage) | Total: \(viewModel.totalElements) | HasMore: \(viewModel.hasMoreData ? "✅" : "❌")")
                .font(.figrCaption2)
                .foregroundColor(.orange)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func debugPostsState() {
        print("📊 DEBUG - Feed State:")
        print("  - Items count: \(viewModel.items.count)")
        print("  - Current page: \(viewModel.currentPage)")
        print("  - Total elements: \(viewModel.totalElements)")
        print("  - Has more data: \(viewModel.hasMoreData)")
        print("  - Is loading: \(viewModel.isLoading)")
        print("  - Is loading more: \(viewModel.isLoadingMore)")
        print("  - Error: \(viewModel.errorMessage ?? "none")")
    }
#endif
}

// MARK: - Extended FeedViewModel for convenience methods
extension FeedViewModel {
    
    // ✅ Métodos de conveniencia para mantener compatibilidad con FeedView anterior
    var posts: [Post] {
        return items
    }
    
    func loadPosts() async {
        await refresh()
    }
    
    func refreshPosts() async {
        await refresh()
    }
    
    func loadMorePosts() async {
        await loadMore()
    }
    
#if DEBUG
    func debugPostsState() {
        print("📊 DEBUG - FeedViewModel State:")
        print("  - Items count: \(items.count)")
        print("  - Current page: \(currentPage)")
        print("  - Total elements: \(totalElements)")
        print("  - Has more data: \(hasMoreData)")
        print("  - Is loading: \(isLoading)")
        print("  - Is loading more: \(isLoadingMore)")
        print("  - Error: \(errorMessage ?? "none")")
    }
#endif
}

// MARK: - Preview
/*
 #Preview {
 FeedView()
 .dependencyInjection()
 }
 */
