//
//  Kingfisher+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import SwiftUI
import Kingfisher

// MARK: - KFImage Extensions for FigrClub
extension KFImage {
    
    /// Configuración estándar para imágenes de posts en el feed
    func postImageStyle() -> some View {
        self
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 400)))
            .placeholder {
                PostImagePlaceholder()
            }
            .retry(maxCount: 3, interval: .seconds(1.5))
            .onSuccess { result in
                Logger.debug("✅ Post image loaded: \(result.source.url?.absoluteString ?? "unknown")")
            }
            .onFailure { error in
                Logger.error("❌ Post image failed: \(error.localizedDescription)")
            }
            .fade(duration: 0.3)
            .aspectRatio(contentMode: .fill)
            .clipped()
    }
    
    /// Configuración para imágenes de perfil de usuario
    func profileImageStyle(size: CGFloat = 50) -> some View {
        self
            .setProcessor(
                RoundCornerImageProcessor(cornerRadius: size / 2)
                |> DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2))
            )
            .placeholder {
                ProfileImagePlaceholder(size: size)
            }
            .retry(maxCount: 2, interval: .seconds(1))
            .fade(duration: 0.2)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
    
    /// Configuración para thumbnails en el marketplace
    func thumbnailStyle(size: CGFloat = 100) -> some View {
        self
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2)))
            .placeholder {
                ThumbnailPlaceholder(size: size)
            }
            .retry(maxCount: 2, interval: .seconds(0.5))
            .fade(duration: 0.2)
            .frame(width: size, height: size)
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    /// Configuración para imágenes de banner/header
    func bannerImageStyle(height: CGFloat = 200) -> some View {
        self
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: UIScreen.main.bounds.width * 2, height: height * 2)))
            .placeholder {
                BannerImagePlaceholder(height: height)
            }
            .retry(maxCount: 3, interval: .seconds(2))
            .fade(duration: 0.4)
            .frame(height: height)
            .aspectRatio(contentMode: .fill)
            .clipped()
    }
    
    /// Configuración para avatares pequeños en comentarios
    func avatarStyle(size: CGFloat = 30) -> some View {
        self.profileImageStyle(size: size)
    }
    
    /// Configuración para imágenes en stories
    func storyImageStyle() -> some View {
        self
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 300)))
            .placeholder {
                StoryImagePlaceholder()
            }
            .retry(maxCount: 2, interval: .seconds(1))
            .fade(duration: 0.3)
            .aspectRatio(9/16, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Custom Placeholder Views
struct PostImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Cargando imagen...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400)
    }
}

struct ProfileImagePlaceholder: View {
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(.gray)
            }
            .frame(width: size, height: size)
    }
}

struct ThumbnailPlaceholder: View {
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "photo.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.gray)
            }
            .frame(width: size, height: size)
    }
}

struct BannerImagePlaceholder: View {
    let height: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("Imagen de banner")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: height)
    }
}

struct StoryImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Historia")
                        .font(.caption)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
            }
    }
}

// MARK: - Animated Loading Placeholder
struct AnimatedImagePlaceholder: View {
    @State private var isAnimating = false
    
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask {
                RoundedRectangle(cornerRadius: cornerRadius)
            }
            .offset(x: isAnimating ? 200 : -200)
            .animation(
                .linear(duration: 1.5).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Image Error View
struct ImageErrorView: View {
    let retryAction: (() -> Void)?
    
    init(retryAction: (() -> Void)? = nil) {
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Error al cargar imagen")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let retryAction = retryAction {
                Button("Reintentar") {
                    retryAction()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - View Modifiers for Easy Integration
struct PostImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ProfileImageModifier: ViewModifier {
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - View Extensions
extension View {
    func postImageStyle() -> some View {
        modifier(PostImageModifier())
    }
    
    func profileImageStyle(size: CGFloat) -> some View {
        modifier(ProfileImageModifier(size: size))
    }
}

// MARK: - Image Caching Utilities
struct ImageCacheHelper {
    
    /// Pre-cargar imágenes importantes
    static func preloadImages(_ urls: [URL]) {
        let prefetcher = ImagePrefetcher(urls: urls) { skippedResources, failedResources, completedResources in
            Logger.debug("🚀 KingfisherCache: Preloaded \(completedResources.count) images, failed: \(failedResources.count)")
        }
        prefetcher.start()
    }
    
    /// Obtener información del cache
    static func getCacheSize() async -> String {
        let cache = ImageCache.default
        let diskSize = try? await cache.diskStorageSize
        // En Kingfisher 8.x usamos el límite de configuración en lugar de totalCount
        let memoryConfigLimit = cache.memoryStorage.config.countLimit
        
        let diskSizeMB = Double(diskSize ?? 0) / 1024 / 1024
        let memorySizeMB = Double(memoryConfigLimit) / 1024 / 1024
        
        return String(format: "Disk: %.1fMB, Memory: %.1fMB", diskSizeMB, memorySizeMB)
    }
    
    /// Limpiar cache de imágenes específicas
    static func clearImages(for urls: [URL]) {
        for url in urls {
            ImageCache.default.removeImage(forKey: url.cacheKey)
        }
    }
}

// MARK: - Performance Optimized Image Loading
struct OptimizedKFImage: View {
    let url: URL?
    let configuration: OptimizedImageConfiguration
    let placeholder: AnyView?
    let failureImage: AnyView?
    
    @State private var loadingState: AsyncImageLoadingState = .loading
    @State private var loadStartTime: Date?
    @State private var retryCount = 0
    
    init(
        url: URL?,
        configuration: OptimizedImageConfiguration = .default,
        @ViewBuilder placeholder: () -> some View = { AnimatedImagePlaceholder() },
        @ViewBuilder failureImage: () -> some View = { ImageErrorView() }
    ) {
        self.url = url
        self.configuration = configuration
        self.placeholder = AnyView(placeholder())
        self.failureImage = AnyView(failureImage())
    }
    
    var body: some View {
        KFImage(url)
            .setProcessor(configuration.processor)
            .placeholder {
                placeholder ?? AnyView(AnimatedImagePlaceholder())
            }
            .onProgress { receivedSize, totalSize in
                let progress = Double(receivedSize) / Double(totalSize)
                configuration.onProgress?(progress)
            }
            .onSuccess { result in
                withAnimation(configuration.successAnimation) {
                    loadingState = .success
                }
                
                if let startTime = loadStartTime {
                    let loadTime = Date().timeIntervalSince(startTime)
                    configuration.onSuccess?(result.image, loadTime)
                    
#if DEBUG
                    Logger.debug("✅ OptimizedKFImage: Loaded in \(String(format: "%.2f", loadTime))s - \(url?.lastPathComponent ?? "unknown")")
#endif
                }
            }
            .onFailure { error in
                loadingState = .failure
                retryCount += 1
                
                if let startTime = loadStartTime {
                    let loadTime = Date().timeIntervalSince(startTime)
                    configuration.onFailure?(error, loadTime, retryCount)
                    
                    Logger.error("❌ OptimizedKFImage: Failed after \(String(format: "%.2f", loadTime))s (retry \(retryCount)) - \(error.localizedDescription)")
                }
                
                if retryCount < configuration.maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + configuration.retryDelay) {
                        loadStartTime = Date()
                        if let url = url {
                            ImageCache.default.removeImage(forKey: url.cacheKey)
                        }
                    }
                }
            }
            .retry(maxCount: configuration.maxRetries, interval: .seconds(configuration.retryDelay))
            .fade(duration: configuration.fadeTransitionDuration)
            .cacheOriginalImage()
            .onAppear {
                loadStartTime = Date()
                configuration.onAppear?()
            }
            .onDisappear {
                configuration.onDisappear?()
            }
    }
}

// MARK: - Convenience Initializers for OptimizedKFImage
extension OptimizedKFImage {
    
    static func fastLoading(
        url: URL?,
        @ViewBuilder placeholder: () -> some View = { ShimmerImagePlaceholder() }
    ) -> OptimizedKFImage {
        OptimizedKFImage(
            url: url,
            configuration: .fastLoading,
            placeholder: placeholder
        )
    }
    
    static func highQuality(
        url: URL?,
        @ViewBuilder placeholder: () -> some View = { AnimatedImagePlaceholder() }
    ) -> OptimizedKFImage {
        OptimizedKFImage(
            url: url,
            configuration: .highQuality,
            placeholder: placeholder
        )
    }
    
    static func custom(
        url: URL?,
        configuration: OptimizedImageConfiguration,
        @ViewBuilder placeholder: () -> some View = { AnimatedImagePlaceholder() },
        @ViewBuilder failureImage: () -> some View = { ImageErrorView() }
    ) -> OptimizedKFImage {
        OptimizedKFImage(
            url: url,
            configuration: configuration,
            placeholder: placeholder,
            failureImage: failureImage
        )
    }
}

// MARK: - AsyncImage Alternative with Kingfisher
struct KFAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    let failure: (Error) -> Failure
    
    @State private var loadingState: AsyncImageLoadingState = .loading
    @State private var loadedImage: UIImage?
    @State private var error: Error?
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping (Error) -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }
    
    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                placeholder()
                    .onAppear {
                        loadImage()
                    }
                
            case .success:
                if let loadedImage = loadedImage {
                    content(Image(uiImage: loadedImage))
                } else {
                    placeholder()
                }
                
            case .failure:
                if let error = error {
                    failure(error)
                } else {
                    placeholder()
                }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            loadingState = .failure
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageResult):
                    self.loadedImage = imageResult.image
                    self.loadingState = .success
                case .failure(let error):
                    self.error = error
                    self.loadingState = .failure
                }
            }
        }
    }
}

// MARK: - Convenience Initializers for KFAsyncImage
extension KFAsyncImage where Placeholder == AnimatedImagePlaceholder, Failure == ImageErrorView {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(
            url: url,
            content: content,
            placeholder: { AnimatedImagePlaceholder() },
            failure: { error in ImageErrorView() }
        )
    }
}

extension KFAsyncImage where Content == Image, Placeholder == AnimatedImagePlaceholder, Failure == ImageErrorView {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: { AnimatedImagePlaceholder() },
            failure: { _ in ImageErrorView() }
        )
    }
}

// MARK: - Smart Image Resizing Modifiers
struct SmartResizeModifier: ViewModifier {
    let targetSize: CGSize
    let contentMode: SwiftUI.ContentMode
    
    func body(content: Content) -> some View {
        content
            .aspectRatio(contentMode: contentMode)
            .frame(
                maxWidth: targetSize.width,
                maxHeight: targetSize.height
            )
            .clipped()
    }
}

extension View {
    func smartResize(to size: CGSize, contentMode: SwiftUI.ContentMode = .fill) -> some View {
        modifier(SmartResizeModifier(targetSize: size, contentMode: contentMode))
    }
}

// MARK: - Gradient Overlay Modifier
struct GradientOverlayModifier: ViewModifier {
    let gradient: LinearGradient
    let blendMode: BlendMode
    
    func body(content: Content) -> some View {
        content
            .overlay(gradient.blendMode(blendMode))
    }
}

extension View {
    func gradientOverlay(
        _ gradient: LinearGradient,
        blendMode: BlendMode = .overlay
    ) -> some View {
        modifier(GradientOverlayModifier(gradient: gradient, blendMode: blendMode))
    }
    
    func darkGradientOverlay() -> some View {
        gradientOverlay(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Progressive Image Loading
struct ProgressiveKFImage: View {
    let url: URL?
    let lowQualityURL: URL?
    
    @State private var showHighQuality = false
    @State private var highQualityLoaded = false
    
    var body: some View {
        ZStack {
            if let lowQualityURL = lowQualityURL {
                KFImage(lowQualityURL)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 100, height: 100)))
                    .fade(duration: 0.2)
                    .opacity(highQualityLoaded ? 0 : 1)
            }
            
            if let url = url {
                KFImage(url)
                    .onSuccess { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            highQualityLoaded = true
                        }
                    }
                    .fade(duration: 0.3)
                    .opacity(highQualityLoaded ? 1 : 0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showHighQuality = true
            }
        }
    }
}

// MARK: - Image with Blur Hash
struct BlurHashKFImage: View {
    let url: URL?
    let blurHash: String?
    
    @State private var imageLoaded = false
    
    var body: some View {
        ZStack {
            if let blurHash = blurHash, !imageLoaded {
                BlurHashView(blurHash: blurHash)
                    .transition(.opacity)
            }
            
            KFImage(url)
                .onSuccess { _ in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        imageLoaded = true
                    }
                }
                .opacity(imageLoaded ? 1 : 0)
        }
    }
}

// MARK: - BlurHash View
struct BlurHashView: View {
    let blurHash: String
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.8, green: 0.9, blue: 1.0),
                        Color(red: 0.9, green: 0.8, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Image Cache Key Utilities
struct ImageCacheKey {
    static func key(for url: URL, size: CGSize? = nil) -> String {
        var key = url.absoluteString
        if let size = size {
            key += "_\(Int(size.width))x\(Int(size.height))"
        }
        return key
    }
}

// MARK: - Image Loading with Analytics
struct AnalyticsKFImage: View {
    let url: URL?
    let analyticsTag: String
    
    @State private var loadStartTime: Date?
    
    var body: some View {
        KFImage(url)
            .onProgress { receivedSize, totalSize in
                let progress = Double(receivedSize) / Double(totalSize)
                trackImageLoadProgress(tag: analyticsTag, progress: progress)
            }
            .onSuccess { _ in
                if let startTime = loadStartTime {
                    let loadTime = Date().timeIntervalSince(startTime)
                    ImagePerformanceMonitor.logImageLoad(
                        url: url ?? URL(string: "unknown")!,
                        loadTime: loadTime,
                        success: true
                    )
                    trackImageLoadSuccess(tag: analyticsTag, loadTime: loadTime)
                }
            }
            .onFailure { error in
                if let startTime = loadStartTime {
                    let loadTime = Date().timeIntervalSince(startTime)
                    ImagePerformanceMonitor.logImageLoad(
                        url: url ?? URL(string: "unknown")!,
                        loadTime: loadTime,
                        success: false
                    )
                    trackImageLoadFailure(tag: analyticsTag, error: error)
                }
            }
            .onAppear {
                loadStartTime = Date()
                trackImageLoadStart(tag: analyticsTag)
            }
    }
    
    private func trackImageLoadStart(tag: String) {
        Logger.debug("📊 Analytics: Image load started - \(tag)")
    }
    
    private func trackImageLoadProgress(tag: String, progress: Double) {
        if progress == 1.0 {
            Logger.debug("📊 Analytics: Image load progress complete - \(tag)")
        }
    }
    
    private func trackImageLoadSuccess(tag: String, loadTime: TimeInterval) {
        Logger.debug("📊 Analytics: Image load success - \(tag) (\(String(format: "%.2f", loadTime))s)")
    }
    
    private func trackImageLoadFailure(tag: String, error: Error) {
        Logger.error("📊 Analytics: Image load failure - \(tag): \(error.localizedDescription)")
    }
}

// MARK: - Shimmer Effect for Loading
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Advanced Placeholder with Shimmer
struct ShimmerImagePlaceholder: View {
    let aspectRatio: CGFloat?
    
    init(aspectRatio: CGFloat? = nil) {
        self.aspectRatio = aspectRatio
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(aspectRatio, contentMode: .fit)
            .shimmer()
            .cornerRadius(8)
    }
}

// MARK: - Optimized Image Grid Cell
struct OptimizedImageGridCell: View {
    let url: URL?
    let size: CGFloat
    let onTap: () -> Void
    
    @State private var isImageVisible = false
    
    var body: some View {
        KFImage(url)
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2)))
            .placeholder {
                ShimmerImagePlaceholder(aspectRatio: 1)
                    .frame(width: size, height: size)
            }
            .fade(duration: 0.3)
            .frame(width: size, height: size)
            .clipped()
            .cornerRadius(8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isImageVisible = true
                }
            }
            .opacity(isImageVisible ? 1 : 0)
            .animation(.easeIn(duration: 0.2), value: isImageVisible)
            .onTapGesture {
                onTap()
            }
    }
}
