//
//  FigrComponents.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI
import Kingfisher

// MARK: - Spacing
enum Spacing {
    static let xxSmall: CGFloat = 2
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
    static let xxxLarge: CGFloat = 48
}

// MARK: - Corner Radius
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
}

// MARK: - Figr Button
struct FigrButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .figrPrimary
            case .secondary: return .figrPrimary.opacity(0.1)
            case .ghost: return .clear
            case .destructive: return .figrError
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .figrPrimary
            case .ghost: return .figrPrimary
            case .destructive: return .white
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .primary, .destructive: return nil
            case .secondary: return .figrPrimary.opacity(0.2)
            case .ghost: return .figrBorder
            }
        }
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .figrFootnote.weight(.medium)
            case .medium: return .figrCallout.weight(.medium)
            case .large: return .figrBody.weight(.medium)
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }
    }
    
    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.small) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .font(size.font)
                        .foregroundColor(style.foregroundColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(style.backgroundColor)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Figr Text Field
struct FigrTextField: View {
    enum Style {
        case `default`
        case rounded
        case underlined
    }
    
    let title: String
    let placeholder: String?
    @Binding var text: String
    let isSecure: Bool
    let validation: ValidationState?
    let style: Style
    let leadingIcon: String?
    let trailingIcon: String?
    let onTrailingIconTap: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @State private var isSecureVisible = false
    
    init(
        title: String,
        placeholder: String? = nil,
        text: Binding<String>,
        isSecure: Bool = false,
        validation: ValidationState? = nil,
        style: Style = .default,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        onTrailingIconTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.validation = validation
        self.style = style
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.onTrailingIconTap = onTrailingIconTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Title
            Text(title)
                .font(.figrSubheadline)
                .foregroundColor(.figrTextSecondary)
            
            // Input Field
            HStack(spacing: Spacing.medium) {
                // Leading Icon
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundColor(.figrTextSecondary)
                        .frame(width: 20, height: 20)
                }
                
                // Text Input
                if isSecure && !isSecureVisible {
                    SecureField(placeholder ?? title, text: $text)
                        .focused($isFocused)
                        .textFieldStyle(FigrTextFieldStyle(style: style, isFocused: isFocused, validation: validation))
                } else {
                    TextField(placeholder ?? title, text: $text)
                        .focused($isFocused)
                        .textFieldStyle(FigrTextFieldStyle(style: style, isFocused: isFocused, validation: validation))
                }
                
                // Security Toggle
                if isSecure {
                    Button(action: { isSecureVisible.toggle() }) {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .foregroundColor(.figrTextSecondary)
                            .frame(width: 20, height: 20)
                    }
                }
                
                // Trailing Icon
                if let trailingIcon = trailingIcon {
                    Button(action: { onTrailingIconTap?() }) {
                        Image(systemName: trailingIcon)
                            .foregroundColor(.figrTextSecondary)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.horizontal, Spacing.large)
            .frame(height: 48)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(style == .rounded ? CornerRadius.medium : 0)
            
            // Validation Message
            if let validation = validation,
               case .invalid(let message) = validation {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.figrError)
                        .font(.figrCaption)
                    
                    Text(message)
                        .font(.figrCaption)
                        .foregroundColor(.figrError)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .default, .rounded:
            return .figrSurface
        case .underlined:
            return .clear
        }
    }
    
    private var borderColor: Color {
        if let validation = validation {
            switch validation {
            case .valid:
                return .figrSuccess
            case .invalid:
                return .figrError
            case .idle:
                return isFocused ? .figrPrimary : .figrBorder
            }
        }
        return isFocused ? .figrPrimary : .figrBorder
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .default, .rounded:
            return 1
        case .underlined:
            return 0
        }
    }
}

// MARK: - Custom Text Field Style
struct FigrTextFieldStyle: TextFieldStyle {
    let style: FigrTextField.Style
    let isFocused: Bool
    let validation: ValidationState?
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.figrBody)
            .foregroundColor(.figrTextPrimary)
    }
}

// MARK: - Figr Card
struct FigrCard<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let backgroundColor: Color
    let shadowRadius: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: Color = .figrSurface,
        shadowRadius: CGFloat = 2,
        cornerRadius: CGFloat = CornerRadius.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.shadowRadius = shadowRadius
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 1)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .figrPrimary))
            
            if let message = message {
                Text(message)
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.figrBackground)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    init(
        title: String = "Algo salió mal",
        message: String,
        buttonTitle: String = "Reintentar",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.xLarge) {
            VStack(spacing: Spacing.medium) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.figrError)
                
                Text(title)
                    .font(.figrTitle3)
                    .foregroundColor(.figrTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            FigrButton(title: buttonTitle, action: action)
                .frame(maxWidth: 200)
        }
        .padding(.horizontal, Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.figrBackground)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let message: String
    let imageName: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        imageName: String = "tray",
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.imageName = imageName
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.xLarge) {
            VStack(spacing: Spacing.medium) {
                Image(systemName: imageName)
                    .font(.system(size: 48))
                    .foregroundColor(.figrTextSecondary)
                
                Text(title)
                    .font(.figrTitle3)
                    .foregroundColor(.figrTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                FigrButton(title: buttonTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(.horizontal, Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.figrBackground)
    }
}

// MARK: - Figr Avatar
struct FigrAvatar: View {
    let imageURL: String?
    let size: CGFloat
    let fallbackText: String
    
    init(imageURL: String?, size: CGFloat = 40, fallbackText: String = "?") {
        self.imageURL = imageURL
        self.size = size
        self.fallbackText = fallbackText
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Circle()
                    .fill(.figrPrimary.opacity(0.1))
                
                Text(fallbackText)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.figrPrimary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Figr Badge
struct FigrBadge: View {
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case primary
        case secondary
        case success
        case warning
        case error
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .figrPrimary
            case .secondary: return .figrSecondary
            case .success: return .figrSuccess
            case .warning: return .figrWarning
            case .error: return .figrError
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .success, .error: return .white
            case .warning: return .black
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.figrCaption.weight(.medium))
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xxSmall)
            .background(style.backgroundColor)
            .cornerRadius(CornerRadius.small)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ToastView<T: View>: View {
    @Binding var isPresented: Bool
    let content: T
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> T) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        if isPresented {
            VStack {
                Spacer()
                
                content
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(CornerRadius.medium)
                    .shadow(radius: 4)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
            }
            .animation(.spring(), value: isPresented)
        }
    }
}



// MARK: - Preview Helpers
#if DEBUG
struct FigrComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.xLarge) {
                // Buttons
                VStack(spacing: Spacing.medium) {
                    FigrButton(title: "Primary Button", style: .primary) { }
                    FigrButton(title: "Secondary Button", style: .secondary) { }
                    FigrButton(title: "Ghost Button", style: .ghost) { }
                    FigrButton(title: "Loading...", style: .primary, isLoading: true) { }
                }
                
                // Text Fields
                VStack(spacing: Spacing.medium) {
                    FigrTextField(title: "Email", text: .constant(""))
                    FigrTextField(title: "Password", text: .constant(""), isSecure: true)
                    FigrTextField(title: "Search", text: .constant(""), leadingIcon: "magnifyingglass")
                }
                
                // Cards
                FigrCard {
                    VStack {
                        Text("Card Title")
                            .font(.figrHeadline)
                        Text("Card content goes here")
                            .font(.figrBody)
                    }
                }
                
                // Avatar and Badge
                HStack {
                    FigrAvatar(imageURL: nil, fallbackText: "JD")
                    FigrBadge(text: "New", style: .primary)
                    FigrBadge(text: "Hot", style: .error)
                }
            }
            .padding()
        }
        .background(.figrBackground)
    }
}

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
        
        Task {
            do {
                if isLiked {
                    try await APIService.shared
                        .request(endpoint: .likePost(post.id), body: nil)
                        .async()
                    
                    Analytics.shared.logPostLike(postId: String(post.id))
                } else {
                    try await APIService.shared
                        .request(endpoint: .unlikePost(post.id), body: nil)
                        .async()
                }
            } catch {
                // Revert optimistic update
                isLiked = previousState
                likesCount = previousCount
                
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
                
                Text(post.createdAt.timeAgoDisplay)
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

// MARK: - Marketplace Item Card
struct MarketplaceItemCard: View {
    let item: MarketplaceItem
    @State private var isFavorited: Bool
    
    init(item: MarketplaceItem) {
        self.item = item
        self._isFavorited = State(initialValue: item.isFavoritedByCurrentUser ?? false)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let firstImage = item.images.first {
                    KFImage(URL(string: firstImage))
                        .placeholder {
                            Rectangle()
                                .fill(.figrBorder)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.figrTextSecondary)
                                )
                        }
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(.figrBorder)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.figrTextSecondary)
                        )
                }
                
                // Favorite Button
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.figrBody)
                        .foregroundColor(isFavorited ? .figrError : .white)
                        .padding(Spacing.small)
                        .background(.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(Spacing.small)
            }
            .cornerRadius(CornerRadius.medium)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(item.title)
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                    .lineLimit(2)
                
                Text("\(item.price, specifier: "%.2f") \(item.currency)")
                    .font(.figrHeadline)
                    .foregroundColor(.figrPrimary)
                
                HStack {
                    Text(item.condition.displayName)
                        .font(.figrCaption)
                        .foregroundColor(.figrTextSecondary)
                    
                    Spacer()
                    
                    if item.status != .available {
                        FigrBadge(text: item.status.displayName, style: .secondary)
                    }
                }
            }
            .padding(.horizontal, Spacing.xSmall)
        }
        .background(.figrSurface)
        .cornerRadius(CornerRadius.medium)
        .defaultShadow()
        .onTapGesture {
            Analytics.shared.logItemView(itemId: String(item.id), category: item.category.name)
        }
    }
    
    private func toggleFavorite() {
        isFavorited.toggle()
        HapticManager.shared.impact(.light)
        
        Task {
            do {
                if isFavorited {
                    try await APIService.shared
                        .request(endpoint: .addToFavorites(item.id), body: nil)
                        .async()
                    
                    Analytics.shared.logItemFavorite(itemId: String(item.id))
                } else {
                    try await APIService.shared
                        .request(endpoint: .removeFromFavorites(item.id), body: nil)
                        .async()
                }
            } catch {
                // Revert optimistic update
                isFavorited.toggle()
                Logger.shared.error("Failed to toggle favorite", error: error, category: "marketplace")
            }
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.figrCallout)
                .foregroundColor(isSelected ? .white : .figrTextPrimary)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(isSelected ? .figrPrimary : .figrSurface)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(isSelected ? .clear : .figrBorder, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Icon
            Image(systemName: notification.type.iconName)
                .font(.figrBody)
                .foregroundColor(notification.type.color)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(notification.title)
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                Text(notification.message)
                    .font(.figrFootnote)
                    .foregroundColor(.figrTextSecondary)
                    .lineLimit(2)
                
                Text(notification.createdAt.timeAgoDisplay)
                    .font(.figrCaption)
                    .foregroundColor(.figrTextSecondary)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(.figrPrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .background(notification.isRead ? .clear : .figrPrimary.opacity(0.05))
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            // Avatar and basic info
            VStack(spacing: Spacing.medium) {
                FigrAvatar(
                    imageURL: user?.profileImageUrl,
                    size: 100,
                    fallbackText: user?.firstName.firstLetterCapitalized ?? "?"
                )
                
                VStack(spacing: Spacing.xSmall) {
                    Text(user?.fullName ?? "Usuario")
                        .font(.figrTitle2)
                        .foregroundColor(.figrTextPrimary)
                    
                    Text("@\(user?.username ?? "username")")
                        .font(.figrCallout)
                        .foregroundColor(.figrTextSecondary)
                    
                    if let bio = user?.bio {
                        Text(bio)
                            .font(.figrBody)
                            .foregroundColor(.figrTextPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // User type badge
                if let userType = user?.userType {
                    FigrBadge(text: userType.displayName, style: .primary)
                }
            }
        }
    }
}

// MARK: - Profile Stats View
struct ProfileStatsView: View {
    let stats: UserStats?
    
    var body: some View {
        HStack {
            StatItem(title: "Posts", value: stats?.postsCount ?? 0)
            Spacer()
            StatItem(title: "Seguidores", value: stats?.followersCount ?? 0)
            Spacer()
            StatItem(title: "Siguiendo", value: stats?.followingCount ?? 0)
            Spacer()
            StatItem(title: "Likes", value: stats?.likesReceived ?? 0)
        }
        .padding(.horizontal, Spacing.xLarge)
    }
}

struct StatItem: View {
    let title: String
    let value: Int
    
    var body: some View {
        VStack(spacing: Spacing.xSmall) {
            Text("\(value)")
                .font(.figrTitle3)
                .foregroundColor(.figrTextPrimary)
            
            Text(title)
                .font(.figrCaption)
                .foregroundColor(.figrTextSecondary)
        }
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
                    
                    Text(comment.createdAt.timeAgoDisplay)
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
}

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
        .background(.figrSurface)
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

// MARK: - Extensions for Display Names

extension ItemCondition {
    var displayName: String {
        switch self {
        case .new: return "Nuevo"
        case .likeNew: return "Como nuevo"
        case .good: return "Bueno"
        case .fair: return "Regular"
        case .poor: return "Malo"
        }
    }
}

extension ItemStatus {
    var displayName: String {
        switch self {
        case .available: return "Disponible"
        case .sold: return "Vendido"
        case .reserved: return "Reservado"
        case .inactive: return "Inactivo"
        }
    }
}

extension NotificationType {
    var iconName: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .follow: return "person.badge.plus"
        case .newPost: return "doc.text.fill"
        case .marketplaceSale: return "cart.fill"
        case .marketplaceQuestion: return "questionmark.circle.fill"
        case .system: return "gear.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .like: return .figrError
        case .comment: return .figrPrimary
        case .follow: return .figrSuccess
        case .newPost: return .figrAccent
        case .marketplaceSale: return .figrWarning
        case .marketplaceQuestion: return .figrSecondary
        case .system: return .figrTextSecondary
        }
    }
}

// MARK: - Supporting Models

struct Comment: Identifiable, Codable {
    let id: Int
    let content: String
    let author: User
    let postId: Int
    let createdAt: String
    let updatedAt: String?
    let likesCount: Int
    let isLikedByCurrentUser: Bool?
}

// MARK: - Comments ViewModel

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService.shared) {
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

struct CreateCommentRequest: Codable {
    let content: String
    let postId: Int
}

// MARK: - Additional API Endpoints for Comments
extension APIEndpoint {
    static func getComments(postId: Int, page: Int, size: Int) -> APIEndpoint {
        return .getComments(postId: postId, page: page, size: size)
    }
    
    static var createComment: APIEndpoint {
        return .createComment
    }
    
    case getComments(postId: Int, page: Int, size: Int)
    case createComment
}

// Update the existing APIEndpoint path and method handling
extension APIEndpoint {
    var pathExtension: String {
        switch self {
        case .getComments(let postId, _, _):
            return "/posts/\(postId)/comments"
        case .createComment:
            return "/comments"
        default:
            return ""
        }
    }
    
    var methodExtension: HTTPMethod {
        switch self {
        case .getComments:
            return .get
        case .createComment:
            return .post
        default:
            return .get
        }
    }
    
    var queryParametersExtension: [String: Any]? {
        switch self {
        case .getComments(_, let page, let size):
            return ["page": page, "size": size]
        default:
            return nil
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Image
                    ProfileImageEditView(imageURL: $viewModel.profileImageURL)
                } header: {
                    Text("Foto de perfil")
                }
                
                Section {
                    TextField("Nombre", text: $viewModel.firstName)
                    TextField("Apellido", text: $viewModel.lastName)
                    TextField("Nombre de usuario", text: $viewModel.username)
                } header: {
                    Text("Información básica")
                }
                
                Section {
                    TextField("Biografía", text: $viewModel.bio, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Biografía")
                } footer: {
                    Text("\(viewModel.bio.count)/\(AppConfig.Validation.maxBioLength)")
                        .foregroundColor(viewModel.bio.count > AppConfig.Validation.maxBioLength ? .figrError : .figrTextSecondary)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.profileSaved {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            await viewModel.loadCurrentProfile()
        }
    }
}

struct ProfileImageEditView: View {
    @Binding var imageURL: String?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: Spacing.medium) {
                FigrAvatar(
                    imageURL: imageURL,
                    size: 100,
                    fallbackText: "?"
                )
                
                Button("Cambiar foto") {
                    showImagePicker = true
                }
                .font(.figrCallout)
                .foregroundColor(.figrPrimary)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage) { image in
                // Handle image upload
                Task {
                    await uploadImage(image)
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) async {
        // Implement image upload logic
        Logger.shared.info("Uploading profile image", category: "profile")
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Edit Profile ViewModel
@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var username = ""
    @Published var bio = ""
    @Published var profileImageURL: String?
    @Published var isLoading = false
    @Published var profileSaved = false
    @Published var errorMessage: String?
    
    private let apiService: APIServiceProtocol
    private let authManager: AuthManager
    
    init(apiService: APIServiceProtocol = APIService.shared,
         authManager: AuthManager = DependencyContainer.shared.resolve(AuthManager.self)) {
        self.apiService = apiService
        self.authManager = authManager
    }
    
    func loadCurrentProfile() async {
        guard let user = authManager.currentUser else { return }
        
        firstName = user.firstName
        lastName = user.lastName
        username = user.username
        bio = user.bio ?? ""
        profileImageURL = user.profileImageUrl
    }
    
    func saveProfile() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        let updateRequest = UpdateUserRequest(
            firstName: firstName,
            lastName: lastName,
            username: username,
            bio: bio.isEmpty ? nil : bio
        )
        
        do {
            let updatedUser: User = try await apiService
                .request(endpoint: .updateUser(userId), body: updateRequest)
                .async()
            
            authManager.updateCurrentUser(updatedUser)
            profileSaved = true
            
            Analytics.shared.logEvent("profile_updated", parameters: [
                "user_id": userId
            ])
            
        } catch {
            errorMessage = "Error al guardar perfil: \(error.localizedDescription)"
            Logger.shared.error("Failed to save profile", error: error, category: "profile")
        }
        
        isLoading = false
    }
}

struct UpdateUserRequest: Codable {
    let firstName: String
    let lastName: String
    let username: String
    let bio: String?
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    SettingsRow(
                        icon: "bell",
                        title: "Notificaciones",
                        action: { viewModel.showNotificationSettings = true }
                    )
                    
                    SettingsRow(
                        icon: "lock",
                        title: "Privacidad",
                        action: { viewModel.showPrivacySettings = true }
                    )
                    
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "Ayuda y Soporte",
                        action: { viewModel.openSupport() }
                    )
                } header: {
                    Text("Configuración")
                }
                
                Section {
                    SettingsRow(
                        icon: "doc.text",
                        title: "Términos de Servicio",
                        action: { viewModel.openTerms() }
                    )
                    
                    SettingsRow(
                        icon: "hand.raised",
                        title: "Política de Privacidad",
                        action: { viewModel.openPrivacyPolicy() }
                    )
                } header: {
                    Text("Legal")
                }
                
                Section {
                    SettingsRow(
                        icon: "info.circle",
                        title: "Acerca de",
                        subtitle: "Versión \(AppConfig.AppInfo.version)",
                        action: { viewModel.showAbout = true }
                    )
                } header: {
                    Text("App")
                }
                
                Section {
                    Button(action: {
                        viewModel.showLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.figrError)
                            Text("Cerrar Sesión")
                                .foregroundColor(.figrError)
                        }
                    }
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $viewModel.showPrivacySettings) {
            PrivacySettingsView()
        }
        .alert("Cerrar Sesión", isPresented: $viewModel.showLogoutConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                viewModel.logout()
                dismiss()
            }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.figrPrimary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.figrTextPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.figrCaption)
                            .foregroundColor(.figrTextSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.figrTextSecondary)
                    .font(.figrCaption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var showNotificationSettings = false
    @Published var showPrivacySettings = false
    @Published var showAbout = false
    @Published var showLogoutConfirmation = false
    
    private let authManager = DependencyContainer.shared.resolve(AuthManager.self)
    
    func openSupport() {
        if let url = URL(string: "mailto:support@figrclub.com") {
            UIApplication.shared.open(url)
        }
    }
    
    func openTerms() {
        if let url = URL(string: "https://figrclub.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://figrclub.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    func logout() {
        authManager.logout()
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var preferences = NotificationPreferencesManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Likes", isOn: $preferences.likesEnabled)
                    Toggle("Comentarios", isOn: $preferences.commentsEnabled)
                    Toggle("Nuevos seguidores", isOn: $preferences.followsEnabled)
                } header: {
                    Text("Actividad Social")
                }
                
                Section {
                    Toggle("Nuevos posts", isOn: $preferences.newPostsEnabled)
                    Toggle("Marketplace", isOn: $preferences.marketplaceEnabled)
                } header: {
                    Text("Contenido")
                }
                
                Section {
                    Toggle("Actualizaciones del sistema", isOn: $preferences.systemEnabled)
                    Toggle("Marketing y promociones", isOn: $preferences.marketingEnabled)
                } header: {
                    Text("Sistema")
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        preferences.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

@MainActor
final class NotificationPreferencesManager: ObservableObject {
    @Published var likesEnabled: Bool
    @Published var commentsEnabled: Bool
    @Published var followsEnabled: Bool
    @Published var newPostsEnabled: Bool
    @Published var marketplaceEnabled: Bool
    @Published var systemEnabled: Bool
    @Published var marketingEnabled: Bool
    
    init() {
        let prefs = NotificationPreferences.load()
        self.likesEnabled = prefs.likesEnabled
        self.commentsEnabled = prefs.commentsEnabled
        self.followsEnabled = prefs.followsEnabled
        self.newPostsEnabled = prefs.newPostsEnabled
        self.marketplaceEnabled = prefs.marketplaceEnabled
        self.systemEnabled = prefs.systemEnabled
        self.marketingEnabled = prefs.marketingEnabled
    }
    
    func save() {
        let prefs = NotificationPreferences(
            likesEnabled: likesEnabled,
            commentsEnabled: commentsEnabled,
            followsEnabled: followsEnabled,
            newPostsEnabled: newPostsEnabled,
            marketplaceEnabled: marketplaceEnabled,
            systemEnabled: systemEnabled,
            marketingEnabled: marketingEnabled
        )
        prefs.save()
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPrivateAccount = false
    @State private var allowDirectMessages = true
    @State private var showOnlineStatus = true
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Cuenta privada", isOn: $isPrivateAccount)
                } header: {
                    Text("Privacidad de la cuenta")
                } footer: {
                    Text("Si tu cuenta es privada, solo las personas que apruebes podrán ver tus posts y seguirte.")
                }
                
                Section {
                    Toggle("Permitir mensajes directos", isOn: $allowDirectMessages)
                    Toggle("Mostrar estado en línea", isOn: $showOnlineStatus)
                } header: {
                    Text("Comunicación")
                }
            }
            .navigationTitle("Privacidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        // Save privacy settings
                        dismiss()
                    }
                }
            }
        }
    }
}


