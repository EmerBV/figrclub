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
                    
                    if let description = post.description {
                        Text(description)
                            .font(.figrBody)
                            .foregroundColor(.figrTextPrimary)
                            .lineLimit(5)
                    }
                    
                    // Hashtags
                    if !post.hashtags.isEmpty {
                        HashtagsView(hashtags: post.hashtags)
                    }
                }
                
                // Images - CORREGIDO para usar PostImage array
                if !post.images.isEmpty {
                    PostImagesView(images: post.images)
                }
                
                // Videos (si existen)
                if !post.videos.isEmpty {
                    PostVideosView(videos: post.videos)
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
        HStack(spacing: Spacing.small) {
            // User Avatar usando Kingfisher
            FigrKingfisherAvatar(
                imageURL: nil, // El modelo Post actual no incluye userProfileImageUrl
                size: 40,
                fallbackText: String(post.userFullName.prefix(1)).uppercased()
            )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(post.userFullName)
                        .font(.figrHeadline)
                        .foregroundColor(.figrTextPrimary)
                    
                    if post.userIsVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(post.createdAt.formatPostDate())
                        .font(.figrCaption)
                        .foregroundColor(.figrTextSecondary)
                    
                    if post.visibility != .public {
                        Image(systemName: visibilityIcon)
                            .font(.caption2)
                            .foregroundColor(.figrTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Menu button
            Button(action: {
                // Handle menu action
            }) {
                Image(systemName: "ellipsis")
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
            }
        }
    }
    
    private var visibilityIcon: String {
        switch post.visibility {
        case .private:
            return "lock.fill"
        case .followers:
            return "person.2.fill"
        case .public:
            return ""
        }
    }
}

// MARK: - Figr Kingfisher Avatar (Componente mejorado)
struct FigrKingfisherAvatar: View {
    let imageURL: String?
    let size: CGFloat
    let fallbackText: String
    
    init(imageURL: String?, size: CGFloat = 40, fallbackText: String = "?") {
        self.imageURL = imageURL
        self.size = size
        self.fallbackText = fallbackText
    }
    
    var body: some View {
        Group {
            if let urlString = imageURL,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                KFImage(url)
                    .setProcessor(
                        ResizingImageProcessor(referenceSize: CGSize(width: size * 2, height: size * 2))
                        |> RoundCornerImageProcessor(cornerRadius: size)
                    )
                    .placeholder {
                        avatarPlaceholder
                    }
                    .onFailure { error in
                        Logger.shared.error("Avatar loading failed", error: error, category: "ui")
                    }
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
            
            Text(fallbackText)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Post Images View
struct PostImagesView: View {
    let images: [PostImage]
    @State private var selectedImageIndex = 0
    @State private var showImageViewer = false
    
    var body: some View {
        Group {
            if images.count == 1 {
                // Single image layout
                singleImageView(images[0])
            } else if images.count <= 4 {
                // Grid layout for 2-4 images
                imagesGridView
            } else {
                // Carousel for 5+ images
                imagesCarouselView
            }
        }
        .sheet(isPresented: $showImageViewer) {
            ImageViewerSheet(images: images, selectedIndex: selectedImageIndex)
        }
    }
    
    // MARK: - Single Image View
    private func singleImageView(_ image: PostImage) -> some View {
        KFImage(URL(string: image.imageUrl))
            .setProcessor(
                ResizingImageProcessor(referenceSize: CGSize(width: 600, height: 400))
                |> RoundCornerImageProcessor(cornerRadius: 12)
            )
            .placeholder {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("Cargando imagen...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            .onFailure { error in
                Logger.shared.error("Image loading failed", error: error, category: "ui")
            }
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxHeight: 300)
            .clipped()
            .cornerRadius(12)
            .onTapGesture {
                selectedImageIndex = 0
                showImageViewer = true
            }
    }
    
    // MARK: - Images Grid View
    private var imagesGridView: some View {
        LazyVGrid(columns: gridColumns, spacing: 4) {
            ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                KFImage(URL(string: image.imageUrl))
                    .setProcessor(
                        ResizingImageProcessor(referenceSize: CGSize(width: 300, height: 300))
                        |> RoundCornerImageProcessor(cornerRadius: 8)
                    )
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            )
                    }
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedImageIndex = index
                        showImageViewer = true
                    }
                    .overlay(
                        // Show count on last image if there are more
                        Group {
                            if index == 3 && images.count > 4 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.black.opacity(0.6))
                                    .overlay(
                                        Text("+\(images.count - 4)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    )
            }
        }
        .frame(height: gridHeight)
    }
    
    // MARK: - Images Carousel View
    private var imagesCarouselView: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                KFImage(URL(string: image.imageUrl))
                    .setProcessor(
                        ResizingImageProcessor(referenceSize: CGSize(width: 600, height: 400))
                        |> RoundCornerImageProcessor(cornerRadius: 12)
                    )
                    .placeholder {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 300)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            )
                    }
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(12)
                    .tag(index)
                    .onTapGesture {
                        showImageViewer = true
                    }
            }
        }
        .frame(height: 300)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
    }
    
    // MARK: - Computed Properties
    private var gridColumns: [GridItem] {
        switch images.count {
        case 2:
            return [GridItem(.flexible()), GridItem(.flexible())]
        case 3:
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        default:
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }
    
    private var gridHeight: CGFloat {
        switch images.count {
        case 2, 4:
            return 200
        case 3:
            return 150
        default:
            return 200
        }
    }
}

// MARK: - Post Videos View (Nuevo componente para videos)
struct PostVideosView: View {
    let videos: [PostVideo]
    @State private var selectedVideoIndex = 0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                    VideoThumbnailView(video: video)
                        .frame(width: 200, height: 120)
                        .onTapGesture {
                            selectedVideoIndex = index
                            // Handle video playback
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let video: PostVideo
    
    var body: some View {
        ZStack {
            // Video thumbnail
            if let thumbnailUrl = video.thumbnailUrl {
                KFImage(URL(string: thumbnailUrl))
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        Image(systemName: "video")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            
            // Play button overlay
            Circle()
                .fill(.black.opacity(0.6))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .offset(x: 2) // Slight offset for visual balance
                )
            
            // Duration label (if available)
            if let duration = video.duration {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Image Viewer Sheet
struct ImageViewerSheet: View {
    let images: [PostImage]
    @State var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                    ZoomableImageView(imageUrl: image.imageUrl)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("\(selectedIndex + 1) de \(images.count)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    let imageUrl: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        KFImage(URL(string: imageUrl))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        lastScale = scale
                        if scale < 1.0 {
                            withAnimation(.spring()) {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        } else if scale > 3.0 {
                            withAnimation(.spring()) {
                                scale = 3.0
                                lastScale = 3.0
                            }
                        }
                    }
                    .simultaneously(with:
                                        DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                                   )
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    if scale > 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.0
                        lastScale = 2.0
                    }
                }
            }
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
            /*
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
             */
            
            if post.isFeatured {
                FigrBadge(text: "Destacado", style: .primary)
            }
            
            if post.isPinned {
                FigrBadge(text: "Fijado", style: .secondary)
            }
            
            Spacer()
            
            // Post visibility
            if post.visibility != .public {
                HStack(spacing: 2) {
                    Image(systemName: visibilityIcon)
                        .font(.caption2)
                        .foregroundColor(.figrTextSecondary)
                    
                    Text(visibilityText)
                        .font(.figrCaption2)
                        .foregroundColor(.figrTextSecondary)
                }
            }
        }
    }
    
    private var visibilityIcon: String {
        switch post.visibility {
        case .private:
            return "lock.fill"
        case .followers:
            return "person.2.fill"
        case .public:
            return ""
        }
    }
    
    private var visibilityText: String {
        switch post.visibility {
        case .private:
            return "Privado"
        case .followers:
            return "Seguidores"
        case .public:
            return ""
        }
    }
}

// MARK: - Hashtags View
struct HashtagsView: View {
    let hashtags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80, maximum: 120))
        ], alignment: .leading, spacing: 8) {
            ForEach(hashtags, id: \.self) { hashtag in
                Text(hashtag)
                    .font(.figrCaption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.opacity(0.1))
                    )
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

// MARK: - Comments View Placeholder
/*
struct CommentsView: View {
    let postId: Int
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Comentarios")
                    .font(.figrTitle2)
                    .padding()
                
                Text("Post ID: \(postId)")
                    .font(.figrCaption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("🚧 En desarrollo")
                    .font(.figrHeadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Comentarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        // Handle close
                    }
                }
            }
        }
    }
}
 */

// MARK: - Post Status Helpers
extension PostStatus {
    var displayName: String {
        switch self {
        case .draft:
            return "Borrador"
        case .published:
            return "Publicado"
        case .archived:
            return "Archivado"
        case .deleted:
            return "Eliminado"
        }
    }
    
    var color: Color {
        switch self {
        case .draft:
            return .orange
        case .published:
            return .green
        case .archived:
            return .gray
        case .deleted:
            return .red
        }
    }
}

// MARK: - Post Visibility Helpers
extension PostVisibility {
    var displayName: String {
        switch self {
        case .public:
            return "Público"
        case .followers:
            return "Seguidores"
        case .private:
            return "Privado"
        }
    }
    
    var icon: String {
        switch self {
        case .public:
            return "globe"
        case .followers:
            return "person.2"
        case .private:
            return "lock"
        }
    }
}
