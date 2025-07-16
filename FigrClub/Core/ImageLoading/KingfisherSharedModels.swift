//
//  KingfisherSharedModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import Foundation
import Kingfisher
import SwiftUI

// MARK: - Shared Cache Info Model
struct KingfisherCacheInfo {
    let diskCacheSize: UInt
    let memoryCacheSize: UInt
    let diskCacheLimit: UInt
    let memoryCacheLimit: UInt
    
    var diskUsagePercentage: Double {
        return Double(diskCacheSize) / Double(diskCacheLimit) * 100
    }
    
    var memoryUsagePercentage: Double {
        return Double(memoryCacheSize) / Double(memoryCacheLimit) * 100
    }
    
    var formattedDiskUsed: String {
        return String(format: "%.1f MB", Double(diskCacheSize) / 1024 / 1024)
    }
    
    var formattedMemoryUsed: String {
        return String(format: "%.1f MB", Double(memoryCacheSize) / 1024 / 1024)
    }
    
    var formattedDiskLimit: String {
        return String(format: "%.1f MB", Double(diskCacheLimit) / 1024 / 1024)
    }
    
    var formattedMemoryLimit: String {
        return String(format: "%.1f MB", Double(memoryCacheLimit) / 1024 / 1024)
    }
}

// MARK: - Build Environment (Single Definition)
enum BuildEnvironment: String {
    case development = "Development"
    case testing = "Testing"
    case production = "Production"
}

struct BuildConfiguration {
    static var environment: BuildEnvironment {
#if DEBUG
        return .development
#elseif TESTING
        return .testing
#else
        return .production
#endif
    }
}

// MARK: - Image Types (Shared Enum)
enum ImageType {
    case profile(size: CGFloat)
    case post(maxSize: CGSize)
    case thumbnail(size: CGSize)
    case banner
    case story
}

// MARK: - Cache Types (Shared Enum)
enum CacheType {
    case memory
    case disk
    case all
    case expired
}

// MARK: - Loading States (Shared Enum)
enum AsyncImageLoadingState {
    case loading
    case success
    case failure
}

// MARK: - Cache Configuration Models
struct KingfisherCacheConfig {
    let diskCacheSize: UInt
    let memoryCacheSize: UInt
    let diskCacheExpiration: TimeInterval
    let memoryCacheExpiration: TimeInterval
    let diskCachePath: String?
    
    static let production = KingfisherCacheConfig(
        diskCacheSize: 200 * 1024 * 1024, // 200 MB
        memoryCacheSize: 50 * 1024 * 1024,  // 50 MB
        diskCacheExpiration: 7 * 24 * 60 * 60, // 7 días
        memoryCacheExpiration: 5 * 60, // 5 minutos
        diskCachePath: "FigrClub_Images"
    )
    
    static let development = KingfisherCacheConfig(
        diskCacheSize: 100 * 1024 * 1024, // 100 MB
        memoryCacheSize: 25 * 1024 * 1024,  // 25 MB
        diskCacheExpiration: 3 * 24 * 60 * 60, // 3 días
        memoryCacheExpiration: 2 * 60, // 2 minutos
        diskCachePath: "FigrClub_Images_Dev"
    )
}

// MARK: - Network Configuration Models
struct KingfisherNetworkConfig {
    let timeoutInterval: TimeInterval
    let retryStrategy: DelayRetryStrategy
    let sessionConfiguration: URLSessionConfiguration
    
    static let `default` = KingfisherNetworkConfig(
        timeoutInterval: 30.0,
        retryStrategy: DelayRetryStrategy(maxRetryCount: 3, retryInterval: .accumulated(2.0)),
        sessionConfiguration: {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30.0
            config.timeoutIntervalForResource = 60.0
            config.httpMaximumConnectionsPerHost = 10
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            return config
        }()
    )
}

// MARK: - Optimized Image Configuration (Shared)
struct OptimizedImageConfiguration {
    let processor: ImageProcessor
    let maxRetries: Int
    let retryDelay: Double
    let fadeTransitionDuration: Double
    let successAnimation: Animation?
    
    let onProgress: ((Double) -> Void)?
    let onSuccess: ((UIImage, TimeInterval) -> Void)?
    let onFailure: ((Error, TimeInterval, Int) -> Void)?
    let onAppear: (() -> Void)?
    let onDisappear: (() -> Void)?
    
    static let `default` = OptimizedImageConfiguration(
        processor: DefaultImageProcessor.default,
        maxRetries: 3,
        retryDelay: 1.0,
        fadeTransitionDuration: 0.3,
        successAnimation: .easeInOut(duration: 0.3),
        onProgress: nil,
        onSuccess: nil,
        onFailure: nil,
        onAppear: nil,
        onDisappear: nil
    )
    
    static let fastLoading = OptimizedImageConfiguration(
        processor: DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)),
        maxRetries: 2,
        retryDelay: 0.5,
        fadeTransitionDuration: 0.2,
        successAnimation: .easeIn(duration: 0.2),
        onProgress: nil,
        onSuccess: nil,
        onFailure: nil,
        onAppear: nil,
        onDisappear: nil
    )
    
    static let highQuality = OptimizedImageConfiguration(
        processor: DownsamplingImageProcessor(size: CGSize(width: 800, height: 800)),
        maxRetries: 5,
        retryDelay: 2.0,
        fadeTransitionDuration: 0.5,
        successAnimation: .spring(response: 0.5, dampingFraction: 0.8),
        onProgress: nil,
        onSuccess: nil,
        onFailure: nil,
        onAppear: nil,
        onDisappear: nil
    )
}

// MARK: - Performance Monitoring Models
struct ImagePerformanceMonitor {
    static func logImageLoad(url: URL, loadTime: TimeInterval, success: Bool) {
#if DEBUG
        let status = success ? "✅" : "❌"
        Logger.debug("📊 Image Load: \(status) \(url.lastPathComponent) - \(String(format: "%.2f", loadTime))s")
#endif
    }
    
    static func logCacheHit(url: URL, cacheType: String) {
#if DEBUG
        Logger.debug("💾 Cache Hit: \(cacheType) - \(url.lastPathComponent)")
#endif
    }
    
    static func logCacheMiss(url: URL) {
#if DEBUG
        Logger.debug("🔍 Cache Miss: \(url.lastPathComponent)")
#endif
    }
}

// MARK: - Image Cache Utilities (Shared)
struct ImageCacheUtilities {
    
    /// Generate cache key for URL with optional size
    static func cacheKey(for url: URL, size: CGSize? = nil) -> String {
        var key = url.absoluteString
        if let size = size {
            key += "_\(Int(size.width))x\(Int(size.height))"
        }
        return key
    }
    
    /// Pre-load images with performance tracking
    static func preloadImages(_ urls: [URL], completion: @escaping (Int, Int) -> Void = { _, _ in }) {
        let prefetcher = ImagePrefetcher(urls: urls) { skippedResources, failedResources, completedResources in
            Logger.debug("🚀 ImageCache: Preloaded \(completedResources.count) images, failed: \(failedResources.count), skipped: \(skippedResources.count)")
            completion(completedResources.count, failedResources.count)
        }
        prefetcher.start()
    }
    
    /// Get formatted cache size string
    static func getFormattedCacheSize() async -> String {
        let cache = ImageCache.default
        let diskSize = try? await cache.diskStorageSize
        // En Kingfisher 8.x usamos una estimación o valor de configuración
        let memoryConfigLimit = cache.memoryStorage.config.countLimit
        
        let diskSizeMB = Double(diskSize ?? 0) / 1024 / 1024
        let memorySizeMB = Double(memoryConfigLimit) / 1024 / 1024
        
        return String(format: "Disk: %.1fMB, Memory: %.1fMB", diskSizeMB, memorySizeMB)
    }
    
    /// Clear specific images from cache
    static func clearImages(for urls: [URL]) {
        for url in urls {
            ImageCache.default.removeImage(forKey: url.cacheKey)
        }
        Logger.debug("🗑️ ImageCache: Cleared \(urls.count) specific images from cache")
    }
    
    /// Get cache statistics
    static func getCacheStatistics() async -> KingfisherCacheInfo {
        let cache = ImageCache.default
        let diskSize = try? await cache.diskStorageSize
        // En Kingfisher 8.x usamos config en lugar de totalCount
        let memorySize = UInt(cache.memoryStorage.config.countLimit)
        
        // Get limits from cache configuration
        let diskLimit = UInt(cache.diskStorage.config.sizeLimit)
        let memoryLimit = UInt(cache.memoryStorage.config.totalCostLimit)
        
        return KingfisherCacheInfo(
            diskCacheSize: diskSize ?? 0,
            memoryCacheSize: memorySize,
            diskCacheLimit: diskLimit,
            memoryCacheLimit: memoryLimit
        )
    }
}

// MARK: - Custom Image Processors (Shared)
struct FigrClubImageProcessor: ImageProcessor {
    let identifier = "com.figrclub.imageprocessor"
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return processImage(image)
        case .data(_):
            return nil
        }
    }
    
    private func processImage(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage? {
        // Aplicar filtros específicos de FigrClub
        // Por ejemplo: watermarks, filtros de marca, etc.
        return image
    }
}

// MARK: - SwiftUI Animation Extensions (Shared)
extension Animation {
    static let defaultImageTransition = Animation.easeInOut(duration: 0.3)
    static let fastImageTransition = Animation.easeIn(duration: 0.2)
    static let smoothImageTransition = Animation.spring(response: 0.5, dampingFraction: 0.8)
}
