//
//  KingfisherConfig.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Kingfisher
import SwiftUI

// MARK: - Kingfisher Configuration
final class KingfisherConfig {
    static let shared = KingfisherConfig()
    
    private init() {}
    
    func configure() {
        // Configure cache
        configureCacheSettings()
        
        // Configure downloader
        configureDownloaderSettings()
        
        Logger.shared.info("Kingfisher configured successfully", category: "kingfisher")
    }
    
    // MARK: - Cache Configuration
    private func configureCacheSettings() {
        let cache = ImageCache.default
        
        // Memory cache settings - Fix: Use correct types
        cache.memoryStorage.config.totalCostLimit = AppConfig.Cache.imageCacheMemoryLimit
        cache.memoryStorage.config.countLimit = 100
        
        // Disk cache settings - Fix: Use correct types
        cache.diskStorage.config.sizeLimit = UInt(AppConfig.Cache.imageCacheDiskLimit)
        cache.diskStorage.config.expiration = .seconds(TimeInterval(AppConfig.Cache.imageCacheExpiration))
        
        Logger.shared.info("Image cache configured - Memory: \(AppConfig.Cache.imageCacheMemoryLimit / (1024*1024))MB, Disk: \(AppConfig.Cache.imageCacheDiskLimit / (1024*1024))MB", category: "kingfisher")
    }
    
    // MARK: - Downloader Configuration
    private func configureDownloaderSettings() {
        let downloader = ImageDownloader.default
        
        // Timeout settings
        downloader.downloadTimeout = AppConfig.API.timeout
        
        // Session configuration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AppConfig.API.timeout
        sessionConfig.timeoutIntervalForResource = AppConfig.API.timeout * 2
        sessionConfig.httpMaximumConnectionsPerHost = 6
        
        downloader.sessionConfiguration = sessionConfig
        
        // Request modifier for auth headers
        downloader.requestsUsePipelining = true
        
        Logger.shared.info("Image downloader configured", category: "kingfisher")
    }
    
    // MARK: - Custom Modifiers
    static func avatarModifier(size: CGFloat) -> AnyModifier {
        return AnyModifier { request in
            var r = request
            
            // Add auth header if needed
            if let token = TokenManager.shared.getAccessToken() {
                r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            return r
        }
    }
    
    // Fix: Correct KingfisherOptionsInfo usage
    static func imageOptions(for imageType: ImageType) -> KingfisherOptionsInfo {
        switch imageType {
        case .avatar:
            return [
                .processor(ResizingImageProcessor(referenceSize: CGSize(width: 200, height: 200))),
                .processor(RoundCornerImageProcessor(cornerRadius: 100)),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .backgroundDecode,
                .requestModifier(avatarModifier(size: 200))
            ]
            
        case .thumbnail:
            return [
                .processor(ResizingImageProcessor(referenceSize: CGSize(width: 300, height: 300))),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .backgroundDecode
            ]
            
        case .fullSize:
            return [
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .backgroundDecode
            ]
            
        case .marketplace:
            return [
                .processor(ResizingImageProcessor(referenceSize: CGSize(width: 400, height: 400))),
                .processor(RoundCornerImageProcessor(cornerRadius: 12)),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .backgroundDecode
            ]
        }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
        Logger.shared.info("Image cache cleared", category: "kingfisher")
    }
    
    func getCacheSize() async throws -> UInt {
        return try await ImageCache.default.diskStorageSize
    }
    
    func cleanExpiredCache() {
        ImageCache.default.cleanExpiredDiskCache()
        Logger.shared.info("Expired cache cleaned", category: "kingfisher")
    }
}

// MARK: - Image Types
enum ImageType {
    case avatar
    case thumbnail
    case fullSize
    case marketplace
}

// MARK: - Custom AsyncImage with Kingfisher
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let imageType: ImageType
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    init(
        url: URL?,
        imageType: ImageType = .thumbnail,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.imageType = imageType
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        KFImage(url)
            .setProcessor(processorForType(imageType))
            .placeholder { _ in
                placeholder()
            }
            .onSuccess { result in
                Logger.shared.debug("Image loaded successfully: \(url?.absoluteString ?? "unknown")", category: "kingfisher")
                Analytics.shared.logEvent("image_loaded", parameters: [
                    "image_type": "\(imageType)",
                    "cache_type": String(describing: result.cacheType)
                ])
            }
            .onFailure { error in
                Logger.shared.error("Image loading failed", error: error, category: "kingfisher")
                Analytics.shared.logError(error, context: "image_loading")
            }
            .fade(duration: 0.25)
            .resizable()
    }
    
    private func processorForType(_ type: ImageType) -> ImageProcessor {
        switch type {
        case .avatar:
            // Fix: Use concatenation operator properly
            return ResizingImageProcessor(referenceSize: CGSize(width: 200, height: 200))
            |> RoundCornerImageProcessor(cornerRadius: 100)
        case .thumbnail:
            return ResizingImageProcessor(referenceSize: CGSize(width: 300, height: 300))
        case .fullSize:
            return DefaultImageProcessor.default
        case .marketplace:
            // Fix: Use concatenation operator properly
            return ResizingImageProcessor(referenceSize: CGSize(width: 400, height: 400))
            |> RoundCornerImageProcessor(cornerRadius: 12)
        }
    }
}

// MARK: - Convenience Extensions
extension KFImage {
    // Fix: Use correct method name and return type
    func figrStyle(for type: ImageType) -> KFImage {
        let options = KingfisherConfig.imageOptions(for: type)
        
        var image = self
        for option in options {
            switch option {
            case .processor(let processor):
                image = image.setProcessor(processor)
            case .scaleFactor(let factor):
                image = image.scaleFactor(factor)
            case .cacheOriginalImage:
                image = image.cacheOriginalImage()
            case .backgroundDecode:
                image = image.backgroundDecode()
            case .requestModifier(let modifier):
                image = image.requestModifier(modifier)
            default:
                break
            }
        }
        return image
    }
}

// MARK: - SwiftUI View Extensions for cached images
extension View {
    func cachedAsyncImage<Placeholder: View>(
        url: URL?,
        imageType: ImageType = .thumbnail,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) -> some View {
        CachedAsyncImage(
            url: url,
            imageType: imageType,
            content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            },
            placeholder: placeholder
        )
    }
}

// MARK: - Modern Kingfisher Image View
struct FigrAsyncImage: View {
    let url: URL?
    let imageType: ImageType
    let size: CGSize?
    
    init(url: URL?, imageType: ImageType = .thumbnail, size: CGSize? = nil) {
        self.url = url
        self.imageType = imageType
        self.size = size
    }
    
    var body: some View {
        KFImage(url)
            .figrStyle(for: imageType)
            .placeholder {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray4)) // Fix: Use UIColor initializer
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Color(.systemGray2))
                    )
            }
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .if(size != nil) { view in
                view.frame(width: size!.width, height: size!.height)
            }
            .clipped()
    }
}

// MARK: - Kingfisher Image Processor Helpers
struct KFImageProcessors {
    static func roundedProcessor(cornerRadius: CGFloat) -> ImageProcessor {
        return RoundCornerImageProcessor(cornerRadius: cornerRadius)
    }
    
    static func resizeProcessor(to size: CGSize) -> ImageProcessor {
        return ResizingImageProcessor(referenceSize: size)
    }
    
    static func avatarProcessor(size: CGFloat) -> ImageProcessor {
        return ResizingImageProcessor(referenceSize: CGSize(width: size, height: size))
        |> RoundCornerImageProcessor(cornerRadius: size / 2)
    }
}

// MARK: - Additional Cache Management
extension KingfisherConfig {
    
    /// Get cache statistics
    func getCacheStatistics() async -> (memoryCount: Int, diskSize: UInt) {
        // Fix: Access public properties only
        let diskSize = (try? await ImageCache.default.diskStorageSize) ?? 0
        // Note: Memory count is not accessible through public API
        return (0, diskSize)
    }
    
    /// Clean cache if needed based on size limit
    func cleanCacheIfNeeded() {
        Task {
            let (_, diskSize) = await getCacheStatistics()
            let limitSize = UInt(AppConfig.Cache.imageCacheDiskLimit)
            
            if diskSize > limitSize {
                await ImageCache.default.cleanExpiredDiskCache()
                Logger.shared.info("Cache cleaned due to size limit exceeded", category: "kingfisher")
            }
        }
    }
    
    /// Configure cache with custom settings
    func configureCache(memoryLimit: Int, diskLimit: UInt, expiration: TimeInterval) {
        let cache = ImageCache.default
        
        cache.memoryStorage.config.totalCostLimit = memoryLimit
        cache.diskStorage.config.sizeLimit = diskLimit
        cache.diskStorage.config.expiration = .seconds(expiration)
        
        Logger.shared.info("Custom cache configuration applied", category: "kingfisher")
    }
    
    /// Get memory cache info (public API only)
    func getMemoryCacheInfo() -> (totalCostLimit: Int, countLimit: Int) {
        let cache = ImageCache.default
        return (
            totalCostLimit: cache.memoryStorage.config.totalCostLimit,
            countLimit: cache.memoryStorage.config.countLimit
        )
    }
}

// MARK: - Helper for conditional view modifier (removed - already exists in View+Extensions)

// MARK: - Improved FigrAvatar using Kingfisher
struct FigrKFAvatar: View {
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
            if let urlString = imageURL, let url = URL(string: urlString) {
                KFImage(url)
                    .setProcessor(KFImageProcessors.avatarProcessor(size: size))
                    .placeholder {
                        avatarPlaceholder
                    }
                    .onFailure { _ in
                        // Fallback handled by placeholder
                    }
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
                .fill(Color(.systemBlue).opacity(0.1))
            
            Text(fallbackText)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(Color(.systemBlue))
        }
    }
}
