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
                Image("logo")
                    .resizable()
                    .frame(width: 44, height: 44)

                Text("FigrClub")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    //.themedTextColor(.primary)
                    .foregroundColor(Color.figrPrimary)
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
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 66, height: 66)
                
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
                    .fill(Color.blue)
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
                        LinearGradient(
                            colors: story.isViewed ? [.gray.opacity(0.3)] : [.purple, .pink, .orange],
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
    
    var body: some View {
        VStack(spacing: 16) {
            // Header del post
            postHeader
                .padding(.horizontal, 16)
            
            // Imagen del post
            postImage
            
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
                // TODO: Mostrar opciones del post
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var postImage: some View {
        KFImage(URL(string: post.imageURL))
            .postImageStyle()
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isLiked.toggle()
                }
                // TODO: Enviar like al servidor
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
            HStack(alignment: .top) {
                Text(post.username)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(post.caption)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
        }
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if post.commentsCount > 0 {
                Button {
                    showComments = true
                } label: {
                    Text(localizationManager.localizedString(for: .seeAllComments, arguments: post.commentsCount))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            // Últimos comentarios
            ForEach(post.recentComments, id: \.username) { comment in
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

// MARK: - Data Models
struct SamplePost: Identifiable {
    let id = UUID()
    let username: String
    let userProfileImage: String
    let imageURL: String
    let caption: String
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let createdAt: Date
    let location: String?
    let recentComments: [Comment]
    
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
            imageURL: "https://picsum.photos/seed/post1/400/400",
            caption: "¡Mi nueva figura de Goku llegó! 😍 #DragonBall #Figuras #Collection",
            likesCount: 127,
            commentsCount: 23,
            sharesCount: 8,
            createdAt: Date().addingTimeInterval(-3600),
            location: "Madrid, España",
            recentComments: [
                SamplePost.Comment(username: "carlos_otaku", text: "¡Qué envidia! ¿Dónde la conseguiste?"),
                SamplePost.Comment(username: "maria_anime", text: "Preciosa! 💖")
            ]
        ),
        SamplePost(
            username: "carlos_otaku",
            userProfileImage: "https://picsum.photos/seed/user2/200/200",
            imageURL: "https://picsum.photos/seed/post2/400/400",
            caption: "Setup actualizado con mi colección favorita 🔥",
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
            imageURL: "https://picsum.photos/seed/post3/400/400",
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

// MARK: - Supporting Views
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

