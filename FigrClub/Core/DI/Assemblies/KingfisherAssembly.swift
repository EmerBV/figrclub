//
//  KingfisherAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import Foundation
import Swinject
import Kingfisher
import UIKit

// MARK: - Kingfisher Assembly for Dependency Injection
final class KingfisherAssembly: Assembly {
    
    func assemble(container: Container) {
        
        // MARK: - Kingfisher Configuration
        container.register(KingfisherConfigurable.self) { _ in
            KingfisherConfig.shared
        }
        .inObjectScope(.container)
        
        // MARK: - Image Cache Service
        container.register(ImageCacheServiceProtocol.self) { resolver in
            let config = resolver.resolve(KingfisherConfigurable.self)!
            return ImageCacheService(config: config)
        }
        .inObjectScope(.container)
        
        // MARK: - Image Downloader Service
        container.register(ImageDownloaderServiceProtocol.self) { resolver in
            let config = resolver.resolve(KingfisherConfigurable.self)!
            return ImageDownloaderService(config: config)
        }
        .inObjectScope(.container)
        
        // MARK: - Image Processing Service
        container.register(ImageProcessingServiceProtocol.self) { _ in
            ImageProcessingService()
        }
        .inObjectScope(.container)
        
        // MARK: - Image Manager (High-level service)
        container.register(ImageManagerProtocol.self) { resolver in
            let cacheService = resolver.resolve(ImageCacheServiceProtocol.self)!
            let downloadService = resolver.resolve(ImageDownloaderServiceProtocol.self)!
            let processingService = resolver.resolve(ImageProcessingServiceProtocol.self)!
            
            return ImageManager(
                cacheService: cacheService,
                downloadService: downloadService,
                processingService: processingService
            )
        }
        .inObjectScope(.container)
    }
}

// MARK: - Image Cache Service Protocol
protocol ImageCacheServiceProtocol {
    func getCacheSize() async -> (disk: UInt, memory: Int)
    func clearAllCache() async
    func clearMemoryCache()
    func clearExpiredCache()
    func getCacheInfo() async -> KingfisherCacheInfo
}

// MARK: - Image Cache Service Implementation
final class ImageCacheService: ImageCacheServiceProtocol {
    
    private let config: KingfisherConfigurable
    private let cache: ImageCache
    
    init(config: KingfisherConfigurable) {
        self.config = config
        self.cache = ImageCache.default
    }
    
    func getCacheSize() async -> (disk: UInt, memory: Int) {
        let diskSize = try? await cache.diskStorageSize
        let memorySize = cache.memoryStorage.config.countLimit > 0 ? cache.memoryStorage.config.countLimit : 0
        return (disk: diskSize ?? 0, memory: memorySize)
    }
    
    func clearAllCache() async {
        cache.clearMemoryCache()
        await cache.clearDiskCache()
        Logger.info("🗑️ ImageCacheService: All cache cleared")
    }
    
    func clearMemoryCache() {
        cache.clearMemoryCache()
        Logger.debug("🗑️ ImageCacheService: Memory cache cleared")
    }
    
    func clearExpiredCache() {
        cache.cleanExpiredDiskCache()
        Logger.debug("🧹 ImageCacheService: Expired cache cleaned")
    }
    
    func getCacheInfo() async -> KingfisherCacheInfo {
        let sizes = await getCacheSize()
        
        // Obtener límites de la configuración
        guard let kingfisherConfig = config as? KingfisherConfig else {
            return KingfisherCacheInfo(
                diskCacheSize: sizes.disk,
                memoryCacheSize: UInt(sizes.memory),
                diskCacheLimit: 200 * 1024 * 1024, // Default 200MB
                memoryCacheLimit: 50 * 1024 * 1024   // Default 50MB
            )
        }
        
        return await kingfisherConfig.getCacheInfo()
    }
}

// MARK: - Image Downloader Service Protocol
protocol ImageDownloaderServiceProtocol {
    func downloadImage(from url: URL) async throws -> UIImage
    func downloadImage(from url: URL, options: KingfisherOptionsInfo) async throws -> UIImage
    func cancelDownload(for url: URL)
    func preloadImages(_ urls: [URL])
}

// MARK: - Image Downloader Service Implementation
final class ImageDownloaderService: ImageDownloaderServiceProtocol {
    
    private let config: KingfisherConfigurable
    private let downloader: ImageDownloader
    private var activeTasks: [URL: DownloadTask] = [:]
    
    init(config: KingfisherConfigurable) {
        self.config = config
        self.downloader = KingfisherManager.shared.downloader
    }
    
    func downloadImage(from url: URL) async throws -> UIImage {
        return try await downloadImage(from: url, options: [])
    }
    
    func downloadImage(from url: URL, options: KingfisherOptionsInfo) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let task = downloader.downloadImage(with: url, options: options) { result in
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult.image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                
                // Remove from active tasks
                self.activeTasks.removeValue(forKey: url)
            }
            
            // Store active task for potential cancellation
            activeTasks[url] = task
        }
    }
    
    func cancelDownload(for url: URL) {
        activeTasks[url]?.cancel()
        activeTasks.removeValue(forKey: url)
        Logger.debug("❌ ImageDownloaderService: Cancelled download for \(url.absoluteString)")
    }
    
    func preloadImages(_ urls: [URL]) {
        let prefetcher = ImagePrefetcher(urls: urls) { skippedResources, failedResources, completedResources in
            Logger.debug("🚀 ImageDownloaderService: Preloaded \(completedResources.count) images, failed: \(failedResources.count), skipped: \(skippedResources.count)")
        }
        prefetcher.start()
    }
}

// MARK: - Image Processing Service Protocol
protocol ImageProcessingServiceProtocol {
    func createProfileProcessor(size: CGFloat) -> ImageProcessor
    func createThumbnailProcessor(size: CGSize) -> ImageProcessor
    func createPostProcessor(maxSize: CGSize) -> ImageProcessor
    func createRoundedProcessor(cornerRadius: CGFloat) -> ImageProcessor
    func createCompositeProcessor(_ processors: [ImageProcessor]) -> ImageProcessor
}

// MARK: - Image Processing Service Implementation
final class ImageProcessingService: ImageProcessingServiceProtocol {
    
    func createProfileProcessor(size: CGFloat) -> ImageProcessor {
        return RoundCornerImageProcessor(cornerRadius: size / 2)
        |> DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2))
    }
    
    func createThumbnailProcessor(size: CGSize) -> ImageProcessor {
        return DownsamplingImageProcessor(size: CGSize(width: size.width * 2, height: size.height * 2))
        |> ResizingImageProcessor(referenceSize: size, mode: .aspectFill)
    }
    
    func createPostProcessor(maxSize: CGSize) -> ImageProcessor {
        return DownsamplingImageProcessor(size: maxSize)
        |> CroppingImageProcessor(size: maxSize)
    }
    
    func createRoundedProcessor(cornerRadius: CGFloat) -> ImageProcessor {
        return RoundCornerImageProcessor(cornerRadius: cornerRadius)
    }
    
    func createCompositeProcessor(_ processors: [ImageProcessor]) -> ImageProcessor {
        return processors.reduce(DefaultImageProcessor.default) { result, processor in
            return result |> processor
        }
    }
}

// MARK: - High-Level Image Manager Protocol
protocol ImageManagerProtocol {
    func loadImage(from url: URL, type: ImageType) async throws -> UIImage
    func preloadImages(_ urls: [URL], type: ImageType)
    func clearCache(type: CacheType)
    func getCacheMetrics() async -> KingfisherCacheInfo
}

// MARK: - Image Manager Implementation
final class ImageManager: ImageManagerProtocol {
    
    private let cacheService: ImageCacheServiceProtocol
    private let downloadService: ImageDownloaderServiceProtocol
    private let processingService: ImageProcessingServiceProtocol
    
    init(
        cacheService: ImageCacheServiceProtocol,
        downloadService: ImageDownloaderServiceProtocol,
        processingService: ImageProcessingServiceProtocol
    ) {
        self.cacheService = cacheService
        self.downloadService = downloadService
        self.processingService = processingService
    }
    
    func loadImage(from url: URL, type: ImageType) async throws -> UIImage {
        let options = createOptions(for: type)
        return try await downloadService.downloadImage(from: url, options: options)
    }
    
    func preloadImages(_ urls: [URL], type: ImageType) {
        downloadService.preloadImages(urls)
    }
    
    func clearCache(type: CacheType) {
        switch type {
        case .memory:
            cacheService.clearMemoryCache()
        case .disk:
            Task {
                await cacheService.clearAllCache()
            }
        case .all:
            Task {
                await cacheService.clearAllCache()
            }
        case .expired:
            cacheService.clearExpiredCache()
        }
    }
    
    func getCacheMetrics() async -> KingfisherCacheInfo {
        let info = await cacheService.getCacheInfo()
        return info
    }
    
    // MARK: - Private Helpers
    private func createOptions(for type: ImageType) -> KingfisherOptionsInfo {
        var options: KingfisherOptionsInfo = [
            .cacheOriginalImage,
            .transition(.fade(0.3))
        ]
        
        switch type {
        case .profile(let size):
            let processor = processingService.createProfileProcessor(size: size)
            options.append(.processor(processor))
            
        case .post(let maxSize):
            let processor = processingService.createPostProcessor(maxSize: maxSize)
            options.append(.processor(processor))
            
        case .thumbnail(let size):
            let processor = processingService.createThumbnailProcessor(size: size)
            options.append(.processor(processor))
            
        case .banner:
            // No additional processing for banners
            break
            
        case .story:
            let processor = processingService.createThumbnailProcessor(size: CGSize(width: 200, height: 300))
            options.append(.processor(processor))
        }
        
        return options
    }
}

// MARK: - Convenience Extensions for DI Container
extension Container {
    
    var imageManager: ImageManagerProtocol {
        return resolve(ImageManagerProtocol.self)!
    }
    
    var imageCacheService: ImageCacheServiceProtocol {
        return resolve(ImageCacheServiceProtocol.self)!
    }
    
    var imageDownloadService: ImageDownloaderServiceProtocol {
        return resolve(ImageDownloaderServiceProtocol.self)!
    }
    
    var imageProcessingService: ImageProcessingServiceProtocol {
        return resolve(ImageProcessingServiceProtocol.self)!
    }
}
