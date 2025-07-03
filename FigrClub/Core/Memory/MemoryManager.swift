//
//  MemoryManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Memory Manager
final class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published var memoryUsage: UInt64 = 0
    @Published var isMemoryPressureHigh = false
    
    private var memoryWarningToken: NSObjectProtocol?
    private var lowMemoryThreshold: UInt64 = 50 * 1024 * 1024 // 50MB
    private var timer: Timer?
    
    private init() {
        setupMemoryWarningObserver()
        startMemoryMonitoring()
    }
    
    deinit {
        if let token = memoryWarningToken {
            NotificationCenter.default.removeObserver(token)
        }
        timer?.invalidate()
    }
    
    // MARK: - Memory Monitoring
    private func setupMemoryWarningObserver() {
        memoryWarningToken = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func startMemoryMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        DispatchQueue.main.async {
            self.memoryUsage = usage
            self.isMemoryPressureHigh = usage > self.lowMemoryThreshold
        }
    }
    
    private func handleMemoryWarning() {
        Logger.shared.warning("Memory warning received", category: "memory")
        
        // Notify all managers to clear caches
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
        
        // Force garbage collection
        Task {
            await clearMemoryCaches()
        }
        
        // Update memory pressure state
        isMemoryPressureHigh = true
    }
    
    @MainActor
    private func clearMemoryCaches() {
        // Clear image cache
        ImageCacheManager.shared.clearMemoryCache()
        
        // Clear other caches
        Logger.shared.info("Memory caches cleared due to memory warning", category: "memory")
    }
    
    // MARK: - Memory Usage
    func getCurrentMemoryUsage() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.phys_footprint : 0
    }
    
    func isMemoryUsageHigh() -> Bool {
        return getCurrentMemoryUsage() > lowMemoryThreshold
    }
    
    func getMemoryPressureLevel() -> MemoryPressureLevel {
        let usage = getCurrentMemoryUsage()
        let threshold = lowMemoryThreshold
        
        if usage > threshold * 2 {
            return .critical
        } else if usage > threshold {
            return .warning
        } else {
            return .normal
        }
    }
}

// MARK: - Memory Pressure Level
enum MemoryPressureLevel {
    case normal
    case warning
    case critical
    
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Image Cache Manager
final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let maxMemoryCost = 50 * 1024 * 1024 // 50MB
    private let maxItems = 100
    
    private init() {
        setupCache()
        setupMemoryWarningObserver()
    }
    
    private func setupCache() {
        memoryCache.totalCostLimit = maxMemoryCost
        memoryCache.countLimit = maxItems
        memoryCache.evictsObjectsWithDiscardedContent = true
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: .memoryWarning,
            object: nil
        )
    }
    
    @objc func clearMemoryCache() {
        memoryCache.removeAllObjects()
        Logger.shared.info("Image memory cache cleared", category: "memory")
    }
    
    // MARK: - Cache Operations
    func setImage(_ image: UIImage, forKey key: String) {
        let cost = image.cost
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func getImage(forKey key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
    }
}

// MARK: - UIImage Memory Extensions
private extension UIImage {
    var cost: Int {
        return Int(size.width * size.height * scale * scale * 4) // 4 bytes per pixel for RGBA
    }
}

// MARK: - Weak Reference Helper
final class WeakReference<T: AnyObject> {
    weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

// MARK: - Memory-Safe Publisher Storage
final class PublisherStorage {
    private var cancellables: [String: AnyCancellable] = [:]
    private let queue = DispatchQueue(label: "com.figrclub.publisher_storage", attributes: .concurrent)
    
    func store(_ cancellable: AnyCancellable, forKey key: String) {
        queue.async(flags: .barrier) {
            self.cancellables[key] = cancellable
        }
    }
    
    func cancel(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cancellables[key]?.cancel()
            self.cancellables.removeValue(forKey: key)
        }
    }
    
    func cancelAll() {
        queue.async(flags: .barrier) {
            self.cancellables.values.forEach { $0.cancel() }
            self.cancellables.removeAll()
        }
    }
    
    deinit {
        cancelAll()
    }
}

// MARK: - Performance Monitor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var measurements: [String: TimeInterval] = [:]
    private let queue = DispatchQueue(label: "com.figrclub.performance", attributes: .concurrent)
    
    private init() {}
    
    func startMeasuring(_ identifier: String) {
        queue.async(flags: .barrier) {
            self.measurements[identifier] = Date().timeIntervalSince1970
        }
    }
    
    func endMeasuring(_ identifier: String) -> TimeInterval? {
        return queue.sync {
            guard let startTime = measurements[identifier] else { return nil }
            let duration = Date().timeIntervalSince1970 - startTime
            measurements.removeValue(forKey: identifier)
            return duration
        }
    }
    
    func measure<T>(_ identifier: String, operation: () throws -> T) rethrows -> T {
        startMeasuring(identifier)
        defer {
            if let duration = endMeasuring(identifier) {
                Logger.shared.info("Performance: \(identifier) took \(String(format: "%.3f", duration))s", category: "performance")
            }
        }
        return try operation()
    }
    
    func measureAsync<T>(_ identifier: String, operation: () async throws -> T) async rethrows -> T {
        startMeasuring(identifier)
        defer {
            if let duration = endMeasuring(identifier) {
                Logger.shared.info("Performance: \(identifier) took \(String(format: "%.3f", duration))s", category: "performance")
            }
        }
        return try await operation()
    }
}

// MARK: - Performance Testing View
#if DEBUG
struct PerformanceTestView: View {
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            List(testResults, id: \.self) { result in
                Text(result)
                    .font(.caption)
            }
            .navigationTitle("Performance Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Run Tests") {
                        runPerformanceTests()
                    }
                }
            }
        }
    }
    
    private func runPerformanceTests() {
        testResults.removeAll()
        
        // Test memory usage
        let memoryUsage = MemoryManager.shared.getCurrentMemoryUsage()
        testResults.append("Memory Usage: \(ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .memory))")
        
        // Test rendering performance
        PerformanceMonitor.shared.measure("test_render") {
            for _ in 0..<1000 {
                _ = UUID().uuidString
            }
        }
        
        // Test network performance
        Task {
            await PerformanceMonitor.shared.measureAsync("test_network") {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
        
        testResults.append("Performance tests completed")
    }
}
#endif
