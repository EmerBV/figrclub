//
//  FeedViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class FeedViewModel: PaginatedViewModel<Post> {
    
    // MARK: - Use Cases
    private let loadPostsUseCase: any LoadPostsUseCase
    private let togglePostLikeUseCase: any TogglePostLikeUseCase
    
    // MARK: - Initialization
    init(
        loadPostsUseCase: any LoadPostsUseCase,
        togglePostLikeUseCase: any TogglePostLikeUseCase
    ) {
        self.loadPostsUseCase = loadPostsUseCase
        self.togglePostLikeUseCase = togglePostLikeUseCase
        super.init()
    }
    
    // MARK: - Override Abstract Methods
    override func loadFirstPage() async {
        await executeWithLoading {
            try await self.loadPostsUseCase.execute(LoadPostsInput(page: 0, size: self.pageSize))
        } onSuccess: { response in
            self.replaceItems(response.content, from: response)
            Logger.shared.info("Feed loaded: \(response.content.count) posts", category: "feed")
        }
    }
    
    override func loadNextPage() async {
        await executeWithLoadingMore {
            try await self.loadPostsUseCase.execute(LoadPostsInput(page: self.currentPage + 1, size: self.pageSize))
        } onSuccess: { response in
            self.appendItems(response.content, from: response)
            Logger.shared.info("More posts loaded: \(response.content.count) posts", category: "feed")
        }
    }
    
    // MARK: - Public Methods
    func toggleLike(for post: Post) {
        guard let currentLikeStatus = post.isLikedByCurrentUser else {
            showErrorMessage("No se puede determinar el estado del like")
            return
        }
        
        Task {
            do {
                let updatedPost = try await togglePostLikeUseCase.execute(
                    TogglePostLikeInput(postId: post.id, isCurrentlyLiked: currentLikeStatus)
                )
                
                // Update the post in the list
                updatePost(updatedPost)
                
            } catch {
                showErrorMessage("Error al actualizar el like: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func updatePost(_ updatedPost: Post) {
        guard let index = items.firstIndex(where: { $0.id == updatedPost.id }) else { return }
        items[index] = updatedPost
    }
}

