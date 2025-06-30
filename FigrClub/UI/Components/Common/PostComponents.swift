//
//  PostComponents.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import SwiftUI
import Kingfisher

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var showComments = false
    @State private var showShareSheet = false
    
    init(post: Post) {
        self.post = post
        self._isLiked = State(initialValue: post.isLikedByCurrentUser ?? false)
        self._likesCount = State(initialValue: post.likesCount)
    }
    
    var body: some View {
        FigrCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Header
                PostHeaderView(post: post)
                
                // Content
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(post.title)
                        .font(.figrHeadline)
                        .foregroundColor(.figrTextPrimary)
                    
                    if let content = post.content {
                        Text(content)
                            .font(.figrBody)
                            .foregroundColor(.figrTextPrimary)
                            .lineLimit(5)
                    }
                    
                    // Hashtags
                    if let hashtags = post.hashtags, !hashtags.isEmpty {
                        HashtagsView(hashtags: hashtags)
                    }
                }
                
                // Images
                if let images = post.images, !images.isEmpty {
                    PostImagesView(images: images)
                }
                
                // Actions
                PostActionsView(
                    isLiked: $isLiked,
                    likesCount: $likesCount,
                    commentsCount: post.commentsCount,
                    sharesCount: post.sharesCount,
                    onLike: { toggleLike() },
                    onComment: { showComments = true },
                    onShare: { showShareSheet = true }
                )
                
                // Metadata
                PostMetadataView(post: post)
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(postId: post.id)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [createShareContent()])
        }
        .onTapGesture {
            Analytics.shared.logEvent("post_tapped", parameters: [
                "post_id": post.id
            ])
        }
    }
    
    private func toggleLike() {
        let previousState = isLiked
        let previousCount = likesCount
        
        // Optimistic update
        isLiked.toggle()
        likesCount += isLiked ? 1 : -1
        
        // Haptic feedback
        HapticManager.shared.impact(.light)
        
        Task.detached(priority: .userInitiated) {
            do {
                if isLiked {
                    let _: EmptyResponse = try await APIService.shared
                        .request(endpoint: .likePost(post.id), body: nil)
                        .async()
                    
                    Analytics.shared.logPostLike(postId: String(post.id))
                } else {
                    let _: EmptyResponse = try await APIService.shared
                        .request(endpoint: .unlikePost(post.id), body: nil)
                        .async()
                }
            } catch {
                // Revert optimistic update on MainActor
                await MainActor.run {
                    isLiked = previousState
                    likesCount = previousCount
                }
                
                Logger.shared.error("Failed to toggle like", error: error, category: "social")
            }
        }
    }
    
    private func createShareContent() -> String {
        return "¡Echa un vistazo a este post en FigrClub!\n\n\"\(post.title)\"\n\nhttps://figrclub.com/post/\(post.id)"
    }
}

// MARK: - Post Header View
struct PostHeaderView: View {
    let post: Post
    
    var body: some View {
        HStack {
            // User Avatar
            FigrAvatar(
                imageURL: post.author?.profileImageUrl,
                size: 40,
                fallbackText: post.author?.firstName.firstLetterCapitalized ?? "?"
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.author?.fullName ?? "Usuario")
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                Text(formatCreatedAt(post.createdAt))
                    .font(.figrCaption)
                    .foregroundColor(.figrTextSecondary)
            }
            
            Spacer()
            
            // Featured Badge
            if post.isFeatured {
                FigrBadge(text: "Destacado", style: .primary)
            }
            
            // More Options
            Button(action: {
                // Handle more options
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.figrTextSecondary)
                    .font(.figrBody)
            }
        }
    }
    
    private func formatCreatedAt(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return "hace un momento"
        }
        return date.timeAgoDisplay
    }
}

// MARK: - Post Images View
struct PostImagesView: View {
    let images: [String]
    @State private var selectedImageIndex = 0
    
    var body: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                KFImage(URL(string: imageUrl))
                    .placeholder {
                        Rectangle()
                            .fill(.figrBorder)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .figrPrimary))
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 300)
                    .clipped()
                    .cornerRadius(CornerRadius.medium)
                    .tag(index)
            }
        }
        .frame(height: 300)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: images.count > 1 ? .automatic : .never))
    }
}

// MARK: - Post Actions View
struct PostActionsView: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.xLarge) {
            // Like Button
            ActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: likesCount,
                color: isLiked ? .figrError : .figrTextSecondary,
                action: onLike
            )
            
            // Comment Button
            ActionButton(
                icon: "bubble.left",
                count: commentsCount,
                color: .figrTextSecondary,
                action: onComment
            )
            
            // Share Button
            ActionButton(
                icon: "square.and.arrow.up",
                count: sharesCount,
                color: .figrTextSecondary,
                action: onShare
            )
            
            Spacer()
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: icon)
                    .font(.figrBody)
                    .foregroundColor(color)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.figrFootnote)
                        .foregroundColor(.figrTextSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Post Metadata View
struct PostMetadataView: View {
    let post: Post
    
    var body: some View {
        HStack {
            if let category = post.category {
                FigrBadge(text: category.name, style: .secondary)
            }
            
            if let location = post.location {
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "location")
                        .font(.figrCaption)
                        .foregroundColor(.figrTextSecondary)
                    
                    Text(location)
                        .font(.figrCaption)
                        .foregroundColor(.figrTextSecondary)
                }
            }
            
            Spacer()
            
            Text("ID: \(post.id)")
                .font(.figrCaption2)
                .foregroundColor(.figrTextSecondary)
        }
    }
}

// MARK: - Hashtags View
struct HashtagsView: View {
    let hashtags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80, maximum: 120))
        ], alignment: .leading, spacing: Spacing.xSmall) {
            ForEach(hashtags, id: \.self) { hashtag in
                Text(hashtag)
                    .font(.figrCaption)
                    .foregroundColor(.figrPrimary)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xxSmall)
                    .background(.figrPrimary.opacity(0.1))
                    .cornerRadius(CornerRadius.small)
                    .onTapGesture {
                        // Handle hashtag tap
                        Analytics.shared.logEvent("hashtag_tapped", parameters: [
                            "hashtag": hashtag
                        ])
                    }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
