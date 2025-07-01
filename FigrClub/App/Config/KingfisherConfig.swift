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
        
        // Memory cache settings
        cache.memoryStorage.config.totalCostLimit = UInt(AppConfig.Cache.imageCacheMemoryLimit)
        cache.memoryStorage.config.countLimit = 100
        
        // Disk cache settings
        cache.diskStorage.config.sizeLimit = Int(AppConfig.Cache.imageCacheDiskLimit)
        cache.diskStorage.config.expiration = .seconds(AppConfig.Cache.imageCacheExpiration)
        
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
                Analytics.shared.logError(error: error, context: "image_loading")
            }
            .fade(duration: 0.25)
            .resizable()
    }
    
    private func processorForType(_ type: ImageType) -> ImageProcessor {
        switch type {
        case .avatar:
            return ResizingImageProcessor(referenceSize: CGSize(width: 200, height: 200))
                |> RoundCornerImageProcessor(cornerRadius: 100)
        case .thumbnail:
            return ResizingImageProcessor(referenceSize: CGSize(width: 300, height: 300))
        case .fullSize:
            return DefaultImageProcessor.default
        case .marketplace:
            return ResizingImageProcessor(referenceSize: CGSize(width: 400, height: 400))
                |> RoundCornerImageProcessor(cornerRadius: 12)
        }
    }
}

// MARK: - Convenience Extensions
extension KFImage {
    func figrStyle(for type: ImageType) -> some View {
        let options = KingfisherConfig.imageOptions(for: type)
        return self.options(options)
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
