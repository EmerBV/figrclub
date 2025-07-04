//
//  MemoryManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import UIKit
import Combine

// MARK: - Memory Manager
final class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published private(set) var isLowMemory = false
    @Published private(set) var currentMemoryUsage: Double = 0
    @Published private(set) var memoryWarningCount = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let memoryThreshold: Double = 80.0 // Porcentaje
    
    private init() {
        setupMemoryMonitoring()
        setupNotifications()
    }
    
    // MARK: - Setup
    private func setupMemoryMonitoring() {
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.checkMemoryUsage()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { _ in
                self.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Memory Monitoring
    private func checkMemoryUsage() {
        let memoryUsage = getCurrentMemoryUsage()
        currentMemoryUsage = memoryUsage
        
        if memoryUsage > memoryThreshold {
            isLowMemory = true
            performMemoryCleanup()
        } else {
            isLowMemory = false
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let totalMemory = ProcessInfo.processInfo.physicalMemory
            let usedMemory = info.resident_size
            return Double(usedMemory) / Double(totalMemory) * 100.0
        }
        
        return 0.0
    }
    
    // MARK: - Memory Warning Handling
    private func handleMemoryWarning() {
        memoryWarningCount += 1
        isLowMemory = true
        
        Logger.shared.warning("Memory warning received. Count: \(memoryWarningCount)", category: "memory")
        
        // Notificar a la app
        NotificationCenter.default.post(
            name: AppConfig.Notifications.lowMemoryWarning,
            object: nil
        )
        
        // Limpiar memoria
        performMemoryCleanup()
    }
    
    // MARK: - Memory Cleanup
    func performMemoryCleanup() {
        Logger.shared.info("Performing memory cleanup", category: "memory")
        
        // Limpiar caché de imágenes
        clearImageCache()
        
        // Limpiar caché de URL
        clearURLCache()
        
        // Limpiar datos temporales
        clearTemporaryData()
        
        // Forzar garbage collection
        autoreleasepool {
            // Operaciones que puedan liberar memoria
        }
        
        // Notificar a los ViewModels para que liberen recursos
        NotificationCenter.default.post(
            name: Notification.Name("MemoryCleanupRequired"),
            object: nil
        )
    }
    
    private func clearImageCache() {
        // Kingfisher cache clearing se maneja en KingfisherConfig
        URLCache.shared.removeAllCachedResponses()
    }
    
    private func clearURLCache() {
        URLCache.shared.removeAllCachedResponses()
        
        // También limpiar cookies si es necesario
        HTTPCookieStorage.shared.cookies?.forEach { cookie in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    
    private func clearTemporaryData() {
        let tempDirectory = FileManager.default.temporaryDirectory
        
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: nil
            )
            
            for file in tempFiles {
                try FileManager.default.removeItem(at: file)
            }
            
            Logger.shared.info("Temporary files cleared", category: "memory")
        } catch {
            Logger.shared.error("Failed to clear temporary files", error: error, category: "memory")
        }
    }
    
    // MARK: - Public Methods
    func reportMemoryUsage() -> MemoryReport {
        let usage = getCurrentMemoryUsage()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = Double(totalMemory) * (usage / 100.0)
        let freeMemory = Double(totalMemory) - usedMemory
        
        return MemoryReport(
            totalMemory: totalMemory,
            usedMemory: UInt64(usedMemory),
            freeMemory: UInt64(freeMemory),
            usagePercentage: usage,
            isLowMemory: isLowMemory,
            warningCount: memoryWarningCount
        )
    }
}

// MARK: - Memory Report
struct MemoryReport {
    let totalMemory: UInt64
    let usedMemory: UInt64
    let freeMemory: UInt64
    let usagePercentage: Double
    let isLowMemory: Bool
    let warningCount: Int
    
    var formattedTotalMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalMemory), countStyle: .memory)
    }
    
    var formattedUsedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedMemory), countStyle: .memory)
    }
    
    var formattedFreeMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(freeMemory), countStyle: .memory)
    }
}
