//
//  CommentsViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIServiceProtocol
    
    nonisolated init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func loadComments(postId: Int) async {
        isLoading = true
        
        do {
            let response: PaginatedResponse<Comment> = try await apiService
                .request(endpoint: .getComments(postId: postId, page: 0, size: 50), body: nil)
                .async()
            
            comments = response.content
            
        } catch {
            errorMessage = "Error al cargar comentarios: \(error.localizedDescription)"
            Logger.shared.error("Failed to load comments", error: error, category: "comments")
        }
        
        isLoading = false
    }
    
    func addComment(postId: Int, text: String) async {
        let request = CreateCommentRequest(content: text, postId: postId)
        
        do {
            let newComment: Comment = try await apiService
                .request(endpoint: .createComment, body: request)
                .async()
            
            comments.insert(newComment, at: 0)
            
            Analytics.shared.logEvent("comment_created", parameters: [
                "post_id": postId
            ])
            
        } catch {
            errorMessage = "Error al crear comentario: \(error.localizedDescription)"
            Logger.shared.error("Failed to create comment", error: error, category: "comments")
        }
    }
}
