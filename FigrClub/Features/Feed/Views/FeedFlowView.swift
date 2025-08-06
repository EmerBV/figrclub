//
//  FeedFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI
import Kingfisher

struct FeedFlowView: View {
    let user: User
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var logoHeight: CGFloat {
        horizontalSizeClass == .regular ? 60 : 40 // iPad : iPhone
    }
    
    @Environment(\.localizationManager) private var localizationManager
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var authStateManager: AuthStateManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Estado local para UI
    @State private var isLoggingOut = false
    @State private var showLogoutConfirmation = false
    @State private var posts: [SamplePost] = samplePosts
    @State private var stories: [SampleStory] = sampleStories
    
    var body: some View {
        FigrNavigationStack {
            FigrRefreshableScrollView(refreshAction: refreshFeed) {
                LazyVStack(spacing: 0) {
                    headerSection
                    storiesSection
                    
                    ForEach(posts) { post in
                        PostView(post: post, currentUser: user)
                            .environmentObject(navigationCoordinator)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        
        // Navegación modal
        /*
         .sheet(isPresented: $navigationCoordinator.showingPostDetail) {
         if let postId = navigationCoordinator.selectedPostId {
         PostDetailSheet(postId: postId, user: user)
         }
         }
         .sheet(isPresented: $navigationCoordinator.showingUserProfile) {
         if let userId = navigationCoordinator.selectedUserId {
         UserProfileSheet(userId: userId, currentUser: user)
         }
         }
         */
        
        // Alert de confirmación para logout
        .alert(localizationManager.localizedString(for: .logout), isPresented: $showLogoutConfirmation) {
            Button(localizationManager.localizedString(for: .cancel), role: .cancel) {
                showLogoutConfirmation = false
            }
            Button(localizationManager.localizedString(for: .logout), role: .destructive) {
                performLogout()
            }
        } message: {
            Text(localizationManager.localizedString(for: .areYouSureToLogout))
        }
        .onChange(of: authStateManager.authState) { oldValue, newValue in
            if case .unauthenticated = newValue {
                isLoggingOut = false
            }
        }
        .onAppear {
            Logger.info("✅ FeedFlowView: Appeared for user: \(user.username)")
        }
    }
    
    private var headerSection: some View {
        HStack {
            HStack(spacing: 0) {
                Image("logo-large")
                    .resizable()
                    .scaledToFit()
                    .frame(height: logoHeight)
                
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                // Botón de notificaciones
                Button {
                    // TODO: Navegar a notificaciones
                } label: {
                    Image(systemName: "heart")
                        .font(.title2)
                        .themedTextColor(.primary)
                }
                
                // Botón de mensajes
                Button {
                    // TODO: Navegar a mensajes
                } label: {
                    Image(systemName: "paperplane")
                        .font(.title2)
                        .themedTextColor(.primary)
                }
                
                // Botón de logout
                Button {
                    showLogoutConfirmation = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .themedTextColor(.primary)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.large)
        .padding(.horizontal, AppTheme.Spacing.large)
    }
    
    // MARK: - Stories View
    private var storiesSection: some View {
        FigrHorizontalScrollView {
            FigrHStack {
                // Tu historia
                UserStoryView(user: user)
                
                // Historias de otros usuarios
                ForEach(stories) { story in
                    StoryView(story: story)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .padding(.bottom, AppTheme.Spacing.large)
    }
    
    // MARK: - Private Methods
    private func performLogout() {
        guard !isLoggingOut else { return }
        
        isLoggingOut = true
        showLogoutConfirmation = false
        
        Logger.info("🚪 FeedFlowView: Starting logout process for user: \(user.username)")
        
        Task {
            await authStateManager.logout()
            Logger.info("✅ FeedFlowView: Logout completed successfully")
        }
    }
    
    private func refreshFeed() async {
        Logger.info("🔄 FeedFlowView: Refreshing feed")
        
        // Simular carga
        try? await Task.sleep(for: .seconds(1))
        
        // Aquí se cargarían los posts reales desde el servidor
        Logger.info("✅ FeedFlowView: Feed refreshed")
    }
}

struct UserStoryView: View {
    let user: User
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                
                // Instagram Style
                /*
                Circle()
                    .stroke(
                        LinearGradient(
                            // TODO: Cambiar el gradient con colores de la app
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 66, height: 66)
                 */
                    
                
                Circle()
                    .stroke(
                        Color.figrPrimary,
                        lineWidth: 1
                    )
                    .frame(width: 60, height: 60)
                
                if user.hasProfileImage {
                    KFImage(URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(user.id)/profile"))
                        .profileImageStyle(size: 60)
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(user.displayName.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color.figrPrimary)
                        )
                }
                
                // Botón de agregar historia
                Circle()
                    .fill(Color.figrBlueAccent)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 22, y: 22)
            }
            
            Text(localizationManager.localizedString(for: .yourStoryString))
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 66)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Story View
struct StoryView: View {
    let story: SampleStory
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(
                        //story.isViewed ? Color.gray.opacity(0.3) : Color.figrBlueAccent,
                        LinearGradient(
                            colors: story.isViewed ? [.gray.opacity(0.3)] : [Color.figrGradientBlueStart, Color.figrGradientBlueEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        
                        lineWidth: 2
                    )
                    .frame(width: 66, height: 66)
                
                KFImage(URL(string: story.userProfileImage))
                    .profileImageStyle(size: 60)
            }
            
            Text(story.username)
                .font(.caption)
                .themedTextColor(.primary)
                .lineLimit(1)
                .frame(width: 66)
        }
        .padding(.top, AppTheme.Spacing.small)
        .padding(.bottom, AppTheme.Spacing.small)
    }
}

// MARK: - Post View
struct PostView: View {
    let post: SamplePost
    let currentUser: User
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var isLiked = false
    @State private var isSaved = false
    @State private var showComments = false
    @State private var showPostOptions = false
    @State private var isExpandedCaption = false
    @State private var captionNeedsExpansion = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header del post
            postHeader
                .padding(.horizontal, 16)
            
            // Imagen(es) del post
            postImageCarousel
            
            // Botones de acción
            actionButtons
                .padding(.horizontal, 16)
            
            // Likes y descripción
            postContent
                .padding(.horizontal, 16)
            
            // Comentarios
            commentsSection
                .padding(.horizontal, 16)
            
            // Tiempo del post
            timestampView
                .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showPostOptions) {
            PostOptionsSheet(post: post, currentUser: currentUser)
                .presentationDetents([.fraction(0.7)])
        }
        .sheet(isPresented: $showComments) {
            PostCommentsSheet(post: post, currentUser: currentUser)
                .presentationDetents([.fraction(0.7)])
        }
    }
    
    private var postHeader: some View {
        HStack {
            // Avatar del usuario
            KFImage(URL(string: post.userProfileImage))
                .profileImageStyle(size: 32)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(post.username)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let location = post.location {
                    Text(location)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Botón de más opciones
            Button {
                showPostOptions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var postImageCarousel: some View {
        Group {
            if post.imageURLs.count == 1 {
                // Imagen única
                KFImage(URL(string: post.imageURLs[0]))
                    .postImageStyle()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isLiked.toggle()
                        }
                        // TODO: Enviar like al servidor
                    }
            } else {
                // Carrusel de imágenes
                PostImageCarousel(imageURLs: post.imageURLs) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isLiked.toggle()
                    }
                    // TODO: Enviar like al servidor
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack {
            // Like
            Button {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isLiked.toggle()
                }
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(isLiked ? .red : .primary)
                
                if post.likesCount > 0 {
                    Text("\(post.likesCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            // Comentar
            Button {
                showComments = true
            } label: {
                Image(systemName: "bubble.right")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                if post.commentsCount > 0 {
                    Text("\(post.commentsCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            // Compartir
            Button {
                // TODO: Compartir post
            } label: {
                Image(systemName: "paperplane")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                if post.sharesCount > 0 {
                    Text("\(post.sharesCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // Guardar
            Button {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isSaved.toggle()
                }
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var postContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Número de likes
            if post.likesCount < 10 {
                Text(localizationManager.localizedString(for: .numberOfProducts, arguments: post.likesCount))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Descripción
            ExpandableCaption(
                username: post.username,
                caption: post.caption,
                isExpanded: $isExpandedCaption
            )
        }
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if post.commentsCount > 2 {
                HStack {
                    Button {
                        showComments = true
                    } label: {
                        Text(localizationManager.localizedString(for: .seeAllComments, arguments: post.commentsCount))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            
            ForEach(Array(post.recentComments.suffix(2).enumerated()), id: \.offset) { index, comment in
                HStack(alignment: .top) {
                    Text(comment.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(comment.text)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var timestampView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(timeAgoString(from: post.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
            }
        }
        .padding(.bottom, 16)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Post Image Carousel
struct PostImageCarousel: View {
    let imageURLs: [String]
    let onDoubleTap: () -> Void
    
    @State private var currentIndex = 0
    
    private let maxImages = 10
    
    var displayedImages: [String] {
        Array(imageURLs.prefix(maxImages))
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(0..<displayedImages.count, id: \.self) { index in
                    KFImage(URL(string: displayedImages[index]))
                        .postImageStyle()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .onTapGesture(count: 2) {
                            onDoubleTap()
                        }
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .aspectRatio(1, contentMode: .fit)
            
            // Indicador de página personalizado
            if displayedImages.count > 1 {
                VStack {
                    Spacer()
                    HStack(alignment: .center) {
                        HStack(spacing: 6) {
                            ForEach(0..<displayedImages.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                        .padding(.bottom, 16)
                    }
                }
            }
            
            // Contador de imágenes
            if displayedImages.count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(currentIndex + 1)/\(displayedImages.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Expandable Caption
struct ExpandableCaption: View {
    let username: String
    let caption: String
    
    @Environment(\.localizationManager) private var localizationManager
    
    @Binding var isExpanded: Bool
    
    @State private var needsExpansion = false
    private let maxLines = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                if needsExpansion {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(alignment: .top) {
                    if isExpanded {
                        // Texto completo
                        Text(attributedText(username + " " + caption, username: username))
                            .font(.system(size: 14))
                            .multilineTextAlignment(.leading)
                    } else {
                        // Texto truncado
                        HStack(alignment: .top, spacing: 0) {
                            Text(attributedText(username + " " + caption, username: username))
                                .font(.system(size: 14))
                                .lineLimit(maxLines)
                                .multilineTextAlignment(.leading)
                                .background(
                                    // Detector invisible para medir el texto
                                    Text(caption)
                                        .font(.system(size: 14))
                                        .lineLimit(nil)
                                        .background(GeometryReader { geometry in
                                            Color.clear.onAppear {
                                                let truncatedHeight = UIFont.systemFont(ofSize: 14).lineHeight * CGFloat(maxLines)
                                                needsExpansion = geometry.size.height > truncatedHeight
                                            }
                                        })
                                        .hidden()
                                )
                            
                            if needsExpansion {
                                Text(localizationManager.localizedString(for: .moreCaptionButton))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!needsExpansion)
        }
    }
    
    private func attributedText(_ fullText: String, username: String) -> AttributedString {
        var attributedString = AttributedString(fullText)
        
        // Hacer el username bold
        if let range = attributedString.range(of: username) {
            attributedString[range].font = .system(size: 14, weight: .semibold)
            attributedString[range].foregroundColor = .primary
        }
        
        // El resto del texto normal
        let captionRange = attributedString.index(attributedString.startIndex, offsetByCharacters: username.count + 1)..<attributedString.endIndex
        if captionRange.lowerBound < attributedString.endIndex {
            attributedString[captionRange].font = .system(size: 14)
            attributedString[captionRange].foregroundColor = .primary
        }
        
        return attributedString
    }
}

// MARK: - Post Options Sheet
struct PostOptionsSheet: View {
    let post: SamplePost
    let currentUser: User
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        FigrNavigationStack {
            VStack(spacing: 0) {
                // Handle visual
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.large)
                
                // Opciones
                VStack(spacing: 0) {
                    PostOptionRow(
                        icon: "bookmark",
                        title: localizationManager.localizedString(for: .save),
                        subtitle: localizationManager.localizedString(for: .addToSavedItemsSubtitle)
                    ) {
                        // TODO: Implementar guardar post
                        dismiss()
                    }
                    
                    if post.username != currentUser.username {
                        PostOptionRow(
                            icon: "person.badge.minus",
                            title: localizationManager.localizedString(for: .unfollowTitle),
                            subtitle: localizationManager.localizedString(for: .unfollowSubtitle, arguments: post.username),
                            isDestructive: true
                        ) {
                            // TODO: Implementar dejar de seguir
                            dismiss()
                        }
                        
                        PostOptionRow(
                            icon: "info.circle",
                            title: localizationManager.localizedString(for: .aboutThisAccountTitle),
                            subtitle: localizationManager.localizedString(for: .aboutThisAccountSubtitle)
                        ) {
                            // TODO: Implementar info de cuenta
                            dismiss()
                        }
                        
                        PostOptionRow(
                            icon: "exclamationmark.triangle",
                            title: localizationManager.localizedString(for: .reportTitle),
                            subtitle: localizationManager.localizedString(for: .reportSubtitle),
                            isDestructive: true
                        ) {
                            // TODO: Implementar reportar post
                            dismiss()
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Post Option Row
struct PostOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Post Comments Sheet
struct PostCommentsSheet: View {
    let post: SamplePost
    let currentUser: User
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    @State private var newCommentText = ""
    @State private var allComments: [SamplePost.Comment] = []
    
    var body: some View {
        FigrNavigationStack {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.large)
                
                Text(localizationManager.localizedString(for: .commentsTitle))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, AppTheme.Spacing.large)
                
                Divider()
                
                // Lista de comentarios
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(allComments, id: \.username) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                Divider()
                
                // Campo de nuevo comentario
                HStack(spacing: 12) {
                    // Avatar del usuario actual
                    if currentUser.hasProfileImage {
                        KFImage(URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(currentUser.id)/profile"))
                            .profileImageStyle(size: 32)
                    } else {
                        Circle()
                            .stroke(
                                Color.figrPrimary,
                                lineWidth: 1
                            )
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(currentUser.displayName.prefix(1).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.figrPrimary)
                            )
                    }
                    
                    // Campo de texto
                    HStack {
                        TextField(localizationManager.localizedString(for: .addAComment), text: $newCommentText, axis: .vertical)
                            .lineLimit(1...4)
                            .textFieldStyle(PlainTextFieldStyle())
                
                        // Botón enviar
                        Button(localizationManager.localizedString(for: .postTitle)) {
                            if !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                let newComment = SamplePost.Comment(
                                    username: currentUser.username,
                                    text: newCommentText
                                )
                                allComments.append(newComment)
                                newCommentText = ""
                                // TODO: Enviar comentario al servidor
                            }
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.figrTextSecondary : Color.figrButtonText)
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .fill(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(.systemGray6) : Color.figrBlueAccent)
                        )
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(AppTheme.Spacing.medium)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.vertical, AppTheme.Spacing.medium)
            }
            
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        // Simular carga de comentarios desde el servidor
        allComments = post.recentComments + [
            SamplePost.Comment(username: "otaku_master", text: "¡Increíble colección!"),
            SamplePost.Comment(username: "anime_lover", text: "¿Dónde conseguiste esa figura?"),
            SamplePost.Comment(username: "collector_spain", text: "Te quedó genial el setup 👌"),
            SamplePost.Comment(username: "figma_fan", text: "Necesito esa figura en mi vida"),
            SamplePost.Comment(username: "manga_reader", text: "¡El mejor personaje de toda la serie!")
        ]
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: SamplePost.Comment
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar del comentarista (placeholder)
            Circle()
                .stroke(
                    Color.figrPrimary,
                    lineWidth: 1
                )
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(comment.username.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("ahora") // TODO: Mostrar hace cuanto se publicó
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 16) {
                    Button(localizationManager.localizedString(for: .likeButtonTitle)) {
                        // TODO: Like comment
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    
                    Button(localizationManager.localizedString(for: .replyButtonTitle)) {
                        // TODO: Reply to comment
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Data Models
struct SamplePost: Identifiable {
    let id = UUID()
    let username: String
    let userProfileImage: String
    let imageURLs: [String]
    let caption: String
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let createdAt: Date
    let location: String?
    let recentComments: [Comment]
    
    // Retrocompatibilidad con imageURL
    var imageURL: String {
        return imageURLs.first ?? ""
    }
    
    struct Comment {
        let username: String
        let text: String
    }
}

struct SampleStory: Identifiable {
    let id = UUID()
    let username: String
    let userProfileImage: String
    let isViewed: Bool
}

// MARK: - Sample Data
extension FeedFlowView {
    static let samplePosts: [SamplePost] = [
        SamplePost(
            username: "ana_figuras",
            userProfileImage: "https://picsum.photos/seed/user1/200/200",
            imageURLs: [
                "https://picsum.photos/seed/post1a/400/400",
                "https://picsum.photos/seed/post1b/400/400",
                "https://picsum.photos/seed/post1c/400/400"
            ],
            caption: "¡Mi nueva colección de figuras de Dragon Ball llegó! No puedo estar más emocionada con estos detalles increíbles. Cada figura tiene una calidad excepcional y los colores son vibrantes. Definitivamente una de mis mejores compras del año. ¿Cuál es vuestra figura favorita de Dragon Ball? 😍 #DragonBall #Figuras #Collection #AnimeCollection #Goku #Vegeta #DragonBallZ",
            likesCount: 127,
            commentsCount: 10,
            sharesCount: 8,
            createdAt: Date().addingTimeInterval(-3600),
            location: "Madrid, España",
            recentComments: [
                SamplePost.Comment(username: "carlos_otaku", text: "¡Qué envidia! ¿Dónde la conseguiste?"),
                SamplePost.Comment(username: "maria_anime", text: "Preciosa! 💖"),
                SamplePost.Comment(username: "setup_goals", text: "Excelente colección! 👌")
            ]
        ),
        SamplePost(
            username: "carlos_otaku",
            userProfileImage: "https://picsum.photos/seed/user2/200/200",
            imageURLs: [
                "https://picsum.photos/seed/post2a/400/400",
                "https://picsum.photos/seed/post2b/400/400",
                "https://picsum.photos/seed/post2c/400/400",
                "https://picsum.photos/seed/post2d/400/400",
                "https://picsum.photos/seed/post2e/400/400"
            ],
            caption: "Setup actualizado con mi colección favorita. Después de meses organizando y reorganizando, finalmente tengo el setup perfecto. Cada figura tiene su lugar especial y la iluminación LED hace que se vean espectaculares por la noche. 🔥",
            likesCount: 89,
            commentsCount: 15,
            sharesCount: 5,
            createdAt: Date().addingTimeInterval(-7200),
            location: nil,
            recentComments: [
                SamplePost.Comment(username: "setup_goals", text: "Increíble setup bro! 👏")
            ]
        ),
        SamplePost(
            username: "maria_anime",
            userProfileImage: "https://picsum.photos/seed/user3/200/200",
            imageURLs: [
                "https://picsum.photos/seed/post3/400/400"
            ],
            caption: "Unboxing de mi pedido de FigrClub! No puedo estar más feliz 📦✨",
            likesCount: 156,
            commentsCount: 31,
            sharesCount: 12,
            createdAt: Date().addingTimeInterval(-10800),
            location: "Barcelona, España",
            recentComments: [
                SamplePost.Comment(username: "ana_figuras", text: "¡Qué ganas de ver el unboxing!"),
                SamplePost.Comment(username: "collector_pro", text: "FigrClub siempre tiene lo mejor")
            ]
        ),
        SamplePost(
            username: "setup_goals",
            userProfileImage: "https://picsum.photos/seed/user4/200/200",
            imageURLs: [
                "https://picsum.photos/seed/post4a/400/400",
                "https://picsum.photos/seed/post4b/400/400",
                "https://picsum.photos/seed/post4c/400/400",
                "https://picsum.photos/seed/post4d/400/400",
                "https://picsum.photos/seed/post4e/400/400",
                "https://picsum.photos/seed/post4f/400/400",
                "https://picsum.photos/seed/post4g/400/400",
                "https://picsum.photos/seed/post4h/400/400",
                "https://picsum.photos/seed/post4i/400/400",
                "https://picsum.photos/seed/post4j/400/400"
            ],
            caption: "Mi habitación gamer completamente transformada. Proceso de 6 meses documentado paso a paso. Desde las estanterías custom hasta la iluminación RGB sincronizada. Todo diseñado para mostrar mi colección de la mejor manera posible. Swipe para ver el antes y después completo! ⚡️🎮",
            likesCount: 245,
            commentsCount: 67,
            sharesCount: 34,
            createdAt: Date().addingTimeInterval(-14400),
            location: "Valencia, España",
            recentComments: [
                SamplePost.Comment(username: "gaming_setup", text: "¡Wow! ¿Cuánto tiempo te llevó?"),
                SamplePost.Comment(username: "rgb_master", text: "Esa iluminación está perfecta 🌈")
            ]
        )
    ]
    
    static let sampleStories: [SampleStory] = [
        SampleStory(username: "ana_figuras", userProfileImage: "https://picsum.photos/seed/story1/200/200", isViewed: false),
        SampleStory(username: "carlos_otaku", userProfileImage: "https://picsum.photos/seed/story2/200/200", isViewed: true),
        SampleStory(username: "maria_anime", userProfileImage: "https://picsum.photos/seed/story3/200/200", isViewed: false),
        SampleStory(username: "setup_goals", userProfileImage: "https://picsum.photos/seed/story4/200/200", isViewed: false),
        SampleStory(username: "collector_pro", userProfileImage: "https://picsum.photos/seed/story5/200/200", isViewed: true)
    ]
}

// NO USADO
// MARK: - Supporting Views
/*
 struct PostDetailSheet: View {
 let postId: String
 let user: User
 @Environment(\.dismiss) private var dismiss
 
 var body: some View {
 FigrNavigationStack {
 VStack(spacing: AppTheme.Spacing.large) {
 Text("Post Detail")
 .font(.title)
 
 Text("Post ID: \(postId)")
 .font(.headline)
 .foregroundColor(.secondary)
 
 Text("Esta funcionalidad estará disponible pronto")
 .font(.callout)
 .foregroundColor(.secondary)
 .multilineTextAlignment(.center)
 
 Spacer()
 }
 .padding()
 .navigationTitle("Post")
 .navigationBarTitleDisplayMode(.inline)
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
 
 struct UserProfileSheet: View {
 let userId: String
 let currentUser: User
 @Environment(\.dismiss) private var dismiss
 
 var body: some View {
 FigrNavigationStack {
 VStack(spacing: AppTheme.Spacing.large) {
 Text("User Profile")
 .font(.title)
 
 Text("User ID: \(userId)")
 .font(.headline)
 .foregroundColor(.secondary)
 
 Text("Esta funcionalidad estará disponible pronto")
 .font(.callout)
 .foregroundColor(.secondary)
 .multilineTextAlignment(.center)
 
 Spacer()
 }
 .padding()
 .navigationTitle("Perfil")
 .navigationBarTitleDisplayMode(.inline)
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
 */

