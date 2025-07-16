//
//  KingfisherConfig.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Kingfisher
import SwiftUI

// MARK: - Kingfisher Configuration Protocol
protocol KingfisherConfigurable {
    func configure()
    func configureDiskCache()
    func configureMemoryCache()
    func configureNetworking()
    func configureProcessor()
    func setupCacheCleanup()
}

// MARK: - Kingfisher Configuration Manager
final class KingfisherConfig: KingfisherConfigurable {
    
    // MARK: - Properties
    private let cacheConfig: KingfisherCacheConfig
    private let networkConfig: KingfisherNetworkConfig
    private let environment: BuildEnvironment
    
    // MARK: - Singleton
    static let shared = KingfisherConfig()
    
    // MARK: - Initialization
    private init() {
        self.environment = BuildConfiguration.environment
        
        switch environment {
        case .production:
            self.cacheConfig = .production
        case .development, .testing:
            self.cacheConfig = .development
        }
        
        self.networkConfig = .default
    }
    
    // MARK: - Public Configuration
    func configure() {
        Logger.info("🖼️ KingfisherConfig: Initializing image loading configuration...")
        
        configureDiskCache()
        configureMemoryCache()
        configureNetworking()
        configureProcessor()
        setupCacheCleanup()
        
        Logger.info("✅ KingfisherConfig: Configuration completed successfully")
        logConfigurationDetails()
    }
    
    // MARK: - Disk Cache Configuration
    func configureDiskCache() {
        let cache = ImageCache.default
        
        // Configurar tamaño del disco
        cache.diskStorage.config.sizeLimit = cacheConfig.diskCacheSize
        
        // Configurar path personalizado si existe
        if let customPath = cacheConfig.diskCachePath {
            do {
                let customDiskStorage = try DiskStorage.Backend<Data>(
                    config: DiskStorage.Config(
                        name: customPath,
                        sizeLimit: cacheConfig.diskCacheSize
                    )
                )
                
                // Crear un nuevo cache con el storage personalizado
                let customCache = ImageCache(
                    memoryStorage: cache.memoryStorage,
                    diskStorage: customDiskStorage
                )
                
                Logger.debug("💾 KingfisherConfig: Custom disk cache path configured: \(customPath)")
            } catch {
                Logger.error("❌ KingfisherConfig: Failed to create custom disk cache: \(error)")
            }
        }
        
        Logger.debug("💾 KingfisherConfig: Disk cache configured - Size: \(cacheConfig.diskCacheSize / 1024 / 1024)MB")
    }
    
    // MARK: - Memory Cache Configuration
    func configureMemoryCache() {
        let cache = ImageCache.default
        
        // Configurar tamaño de memoria
        cache.memoryStorage.config.totalCostLimit = Int(cacheConfig.memoryCacheSize)
        
        // Configurar número máximo de objetos en memoria
        cache.memoryStorage.config.countLimit = 100
        
        // Configurar expiración de memoria
        cache.memoryStorage.config.expiration = .seconds(cacheConfig.memoryCacheExpiration)
        
        // Limpiar memoria automáticamente bajo presión
        cache.memoryStorage.config.cleanInterval = 60 // 1 minuto
        
        Logger.debug("🧠 KingfisherConfig: Memory cache configured - Size: \(cacheConfig.memoryCacheSize / 1024 / 1024)MB, Count limit: 100")
    }
    
    // MARK: - Network Configuration
    func configureNetworking() {
        let modifier = AnyModifier { request in
            var modifiedRequest = request
            
            // Headers personalizados
            modifiedRequest.addValue("FigrClub-iOS", forHTTPHeaderField: "User-Agent")
            modifiedRequest.addValue("image/*", forHTTPHeaderField: "Accept")
            
            // Cache control
            modifiedRequest.addValue("max-age=86400", forHTTPHeaderField: "Cache-Control")
            
            return modifiedRequest
        }
        
        // Configurar downloader global
        KingfisherManager.shared.downloader.sessionConfiguration = networkConfig.sessionConfiguration
        KingfisherManager.shared.downloader.downloadTimeout = networkConfig.timeoutInterval
        
        // Configurar estrategia de retry
        KingfisherManager.shared.defaultOptions = [
            .requestModifier(modifier),
            .retryStrategy(networkConfig.retryStrategy),
            .cacheOriginalImage,
            .transition(.fade(0.3))
        ]
        
        Logger.debug("🌐 KingfisherConfig: Network configuration applied - Timeout: \(networkConfig.timeoutInterval)s")
    }
    
    // MARK: - Image Processor Configuration
    func configureProcessor() {
        // Configurar procesadores por defecto para optimización
        let compressionProcessor = DownsamplingImageProcessor(size: CGSize(width: 300, height: 300))
        let roundCornerProcessor = RoundCornerImageProcessor(cornerRadius: 8)
        
        // Registrar procesadores comunes
        registerCommonProcessors()
        
        Logger.debug("🎨 KingfisherConfig: Image processors configured")
    }
    
    // MARK: - Cache Cleanup
    func setupCacheCleanup() {
        // Limpiar caché automáticamente cada 24 horas
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            Task {
                await self.performCacheCleanup()
            }
        }
        
        // Limpiar cuando la app entre en background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.performBackgroundCleanup()
            }
        }
        
        // Limpiar cuando haya memory warning
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.performMemoryPressureCleanup()
            }
        }
        
        Logger.debug("🧹 KingfisherConfig: Automatic cache cleanup configured")
    }
    
    // MARK: - Private Helper Methods
    private func registerCommonProcessors() {
        // Aquí podrías registrar procesadores personalizados para FigrClub
        // Por ejemplo: filtros de la app, watermarks, etc.
    }
    
    private func performCacheCleanup() async {
        let cache = ImageCache.default
        
        // Limpiar archivos expirados del disco
        await cache.cleanExpiredDiskCache()
        
        // Limpiar memoria si está por encima del 80% de capacidad
        let memoryCacheThreshold = Int(Double(cacheConfig.memoryCacheSize) * 0.8)
        
        if cache.memoryStorage.config.countLimit > memoryCacheThreshold {
            cache.clearMemoryCache()
            Logger.debug("🧹 KingfisherConfig: Memory cache cleared due to high usage")
        }
        
        Logger.debug("🧹 KingfisherConfig: Periodic cache cleanup completed")
    }
    
    private func performBackgroundCleanup() async {
        let cache = ImageCache.default
        
        // Limpiar memoria cuando la app está en background
        cache.clearMemoryCache()
        
        // Limpiar archivos expirados
        await cache.cleanExpiredDiskCache()
        
        Logger.debug("🧹 KingfisherConfig: Background cleanup completed")
    }
    
    private func performMemoryPressureCleanup() async {
        let cache = ImageCache.default
        
        // Limpiar inmediatamente la memoria bajo presión
        cache.clearMemoryCache()
        
        Logger.warning("⚠️ KingfisherConfig: Emergency memory cleanup performed")
    }
    
    private func logConfigurationDetails() {
        Logger.info("📋 KingfisherConfig Details:")
        Logger.info("  💾 Disk Cache: \(cacheConfig.diskCacheSize / 1024 / 1024)MB")
        Logger.info("  🧠 Memory Cache: \(cacheConfig.memoryCacheSize / 1024 / 1024)MB, \(Int(cacheConfig.memoryCacheExpiration / 60)) minutes retention")
        Logger.info("  🌐 Network Timeout: \(networkConfig.timeoutInterval)s")
        Logger.info("  🏗️ Environment: \(environment.rawValue)")
    }
}

// MARK: - Cache Management Extensions
extension KingfisherConfig {
    
    /// Obtener información actual del caché
    func getCacheInfo() async -> KingfisherCacheInfo {
        return await ImageCacheUtilities.getCacheStatistics()
    }
    
    /// Limpiar todo el caché manualmente
    func clearAllCache() async {
        let cache = ImageCache.default
        cache.clearMemoryCache()
        await cache.clearDiskCache()
        
        Logger.info("🗑️ KingfisherConfig: All cache cleared manually")
    }
    
    /// Limpiar solo la memoria
    func clearMemoryCache() {
        ImageCache.default.clearMemoryCache()
        Logger.debug("🗑️ KingfisherConfig: Memory cache cleared manually")
    }
}

// MARK: - SwiftUI Image Loading Extensions
extension KingfisherConfig {
    
    /// Opciones por defecto para cargar imágenes en SwiftUI
    static func defaultSwiftUIOptions() -> KingfisherOptionsInfo {
        return [
            .cacheOriginalImage,
            .transition(.fade(0.3)),
            .retryStrategy(DelayRetryStrategy(maxRetryCount: 3, retryInterval: .accumulated(1.5))),
            .keepCurrentImageWhileLoading
        ]
    }
    
    /// Opciones para imágenes de perfil (circulares, menor resolución)
    static func profileImageOptions() -> KingfisherOptionsInfo {
        return [
            .processor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))),
            .processor(RoundCornerImageProcessor(cornerRadius: 100)),
            .cacheOriginalImage,
            .transition(.fade(0.2))
        ]
    }
    
    /// Opciones para imágenes de posts (alta calidad)
    static func postImageOptions() -> KingfisherOptionsInfo {
        return [
            .processor(DownsamplingImageProcessor(size: CGSize(width: 800, height: 800))),
            .cacheOriginalImage,
            .transition(.fade(0.4)),
            .keepCurrentImageWhileLoading
        ]
    }
    
    /// Opciones para thumbnails (baja resolución, rápida carga)
    static func thumbnailOptions() -> KingfisherOptionsInfo {
        return [
            .processor(DownsamplingImageProcessor(size: CGSize(width: 150, height: 150))),
            .cacheOriginalImage,
            .transition(.none)
        ]
    }
}

// MARK: - Debugging and Monitoring
extension KingfisherConfig {
    
    /// Habilitar debugging detallado (solo para desarrollo)
    func enableDebugMode() {
#if DEBUG
        // Habilitar logs detallados de Kingfisher
        KingfisherManager.shared.cache.memoryStorage.config.cleanInterval = 10 // Más frecuente para testing
        Logger.debug("🐛 KingfisherConfig: Debug mode enabled")
#endif
    }
    
    /// Métricas de rendimiento del cache
    func logCacheMetrics() async {
        let info = await getCacheInfo()
        
        Logger.info("📊 KingfisherConfig Cache Metrics:")
        Logger.info("  💾 Disk: \(info.diskCacheSize / 1024 / 1024)MB / \(info.diskCacheLimit / 1024 / 1024)MB (\(String(format: "%.1f", info.diskUsagePercentage))%)")
        Logger.info("  🧠 Memory: \(info.memoryCacheSize / 1024 / 1024)MB / \(info.memoryCacheLimit / 1024 / 1024)MB (\(String(format: "%.1f", info.memoryUsagePercentage))%)")
    }
}
