//
//  CommentsComponents.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import SwiftUI

// MARK: - Supporting Models
struct Comment: Identifiable, Codable {
    let id: Int
    let content: String
    let author: User  // ← Tiene la propiedad author
    let postId: Int
    let createdAt: String
    let updatedAt: String?
    let likesCount: Int
    let isLikedByCurrentUser: Bool?
}

struct CreateCommentRequest: Codable {
    let postId: Int
    let content: String
    var parentCommentId: Int? = nil
    
    init(content: String, postId: Int, parentCommentId: Int? = nil) {
        self.content = content
        self.postId = postId
        self.parentCommentId = parentCommentId
    }
}

// MARK: - Comments View
struct CommentsView: View {
    let postId: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommentsViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.comments.isEmpty {
                    EmptyStateView(
                        title: "Sin comentarios",
                        message: "Sé el primero en comentar",
                        imageName: "bubble.left"
                    )
                } else {
                    List(viewModel.comments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
                
                // Comment input
                CommentInputView { commentText in
                    Task {
                        await viewModel.addComment(postId: postId, text: commentText)
                    }
                }
            }
            .navigationTitle("Comentarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadComments(postId: postId)
        }
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            FigrAvatar(
                imageURL: comment.author.profileImageUrl,
                size: 32,
                fallbackText: comment.author.firstName.firstLetterCapitalized
            )
            
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack {
                    Text(comment.author.fullName)
                        .font(.figrCallout.weight(.medium))
                        .foregroundColor(.figrTextPrimary)
                    
                    Spacer()
                    
                    Text(formatCreatedAt(comment.createdAt))
                        .font(.figrCaption)
                        .foregroundColor(.figrTextSecondary)
                }
                
                Text(comment.content)
                    .font(.figrBody)
                    .foregroundColor(.figrTextPrimary)
            }
        }
        .padding(.vertical, Spacing.xSmall)
    }
    
    private func formatCreatedAt(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return "hace un momento"
        }
        return date.timeAgoDisplay
    }
}

// MARK: - Comment Input View
struct CommentInputView: View {
    @State private var commentText = ""
    let onSubmit: (String) -> Void
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            TextField("Escribe un comentario...", text: $commentText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
            
            Button(action: {
                guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                onSubmit(commentText)
                commentText = ""
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.figrPrimary)
                    .font(.figrBody)
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        //.background(.figrSurface)
    }
}
