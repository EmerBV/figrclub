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
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        LoadingView(message: "Cargando posts...")
                    } else if viewModel.posts.isEmpty {
                        EmptyStateView(
                            title: "No hay posts",
                            message: "Sé el primero en compartir algo increíble",
                            imageName: "doc.text",
                            buttonTitle: "Crear Post"
                        ) {
                            // Handle create post
                        }
                    } else {
                        ForEach(viewModel.posts) { post in
                            PostCardView(post: post)
                                .onAppear {
                                    if post == viewModel.posts.last {
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                                }
                        }
                        
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
                await viewModel.refreshPosts()
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadPosts()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "FeedView")
        }
    }
}
