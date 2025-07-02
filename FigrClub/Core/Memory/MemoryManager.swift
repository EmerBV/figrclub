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
final class MemoryManager {
    static let shared = MemoryManager()
    
    private var memoryWarningToken: NSObjectProtocol?
    private var lowMemoryThreshold: UInt64 = 50 * 1024 * 1024 // 50MB
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    deinit {
        if let token = memoryWarningToken {
            NotificationCenter.default.removeObserver(token)
        }
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
    
    private func handleMemoryWarning() {
        Logger.shared.warning("Memory warning received", category: "memory")
        
        // Notify all managers to clear caches
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
        
        // Force garbage collection
        Task {
            await clearMemoryCaches()
        }
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

// MARK: - Enhanced BaseViewModel with Memory Management
extension BaseViewModel {
    
    /// Safe publisher storage with automatic cleanup
    private static var publisherStorages: [ObjectIdentifier: PublisherStorage] = [:]
    private static let storageQueue = DispatchQueue(label: "com.figrclub.storage_queue", attributes: .concurrent)
    
    var publisherStorage: PublisherStorage {
        let id = ObjectIdentifier(self)
        
        return Self.storageQueue.sync {
            if let existing = Self.publisherStorages[id] {
                return existing
            }
            
            let newStorage = PublisherStorage()
            Self.storageQueue.async(flags: .barrier) {
                Self.publisherStorages[id] = newStorage
            }
            return newStorage
        }
    }
    
    /// Cleanup method to call in deinit
    func cleanupMemory() {
        let id = ObjectIdentifier(self)
        Self.storageQueue.async(flags: .barrier) {
            Self.publisherStorages[id]?.cancelAll()
            Self.publisherStorages.removeValue(forKey: id)
        }
        
        cancellables.removeAll()
        errorTimer?.invalidate()
        errorTimer = nil
    }
}

// MARK: - Performance Monitor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var startTimes: [String: CFTimeInterval] = [:]
    private let queue = DispatchQueue(label: "com.figrclub.performance", attributes: .concurrent)
    
    private init() {}
    
    func startMeasuring(_ identifier: String) {
        queue.async(flags: .barrier) {
            self.startTimes[identifier] = CACurrentMediaTime()
        }
    }
    
    func endMeasuring(_ identifier: String, category: String = "performance") {
        let endTime = CACurrentMediaTime()
        
        queue.async(flags: .barrier) {
            guard let startTime = self.startTimes[identifier] else {
                Logger.shared.warning("No start time found for identifier: \(identifier)", category: category)
                return
            }
            
            let duration = endTime - startTime
            self.startTimes.removeValue(forKey: identifier)
            
            Logger.shared.info("⏱️ \(identifier): \(String(format: "%.3f", duration * 1000))ms", category: category)
            
            // Log slow operations
            if duration > 1.0 {
                Logger.shared.warning("🐌 Slow operation detected: \(identifier) took \(String(format: "%.3f", duration))s", category: category)
            }
        }
    }
    
    func measure<T>(_ identifier: String, category: String = "performance", operation: () throws -> T) rethrows -> T {
        startMeasuring(identifier)
        defer { endMeasuring(identifier, category: category) }
        return try operation()
    }
    
    func measureAsync<T>(_ identifier: String, category: String = "performance", operation: () async throws -> T) async rethrows -> T {
        startMeasuring(identifier)
        defer { endMeasuring(identifier, category: category) }
        return try await operation()
    }
}

// MARK: - View Performance Extensions
extension View {
    
    /// Measure view rendering performance
    func measureRenderTime(_ identifier: String) -> some View {
        self
            .onAppear {
                PerformanceMonitor.shared.startMeasuring("render_\(identifier)")
            }
            .onDisappear {
                PerformanceMonitor.shared.endMeasuring("render_\(identifier)", category: "ui")
            }
    }
    
    /// Optimize for large lists
    func optimizedForLargeList() -> some View {
        self
            .drawingGroup() // Flatten view hierarchy for better performance
    }
    
    /// Memory-efficient conditional rendering
    func conditionalRender<T: View>(_ condition: Bool, @ViewBuilder content: () -> T) -> some View {
        Group {
            if condition {
                content()
            } else {
                self
            }
        }
    }
}

// MARK: - Lazy Loading Helper
struct LazyView<Content: View>: View {
    private let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    init(@ViewBuilder _ build: @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

// MARK: - Memory-Efficient Image View
struct MemoryEfficientAsyncImage: View {
    let url: URL?
    let placeholder: AnyView?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: URL?, @ViewBuilder placeholder: () -> some View = { Color.gray.opacity(0.3) }) {
        self.url = url
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            cancelLoading()
        }
    }
    
    private func loadImage() {
        guard let url = url, image == nil, !isLoading else { return }
        
        // Check cache first
        let cacheKey = url.absoluteString
        if let cachedImage = ImageCacheManager.shared.getImage(forKey: cacheKey) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                await MainActor.run {
                    if let loadedImage = UIImage(data: data) {
                        // Cache the image
                        ImageCacheManager.shared.setImage(loadedImage, forKey: cacheKey)
                        self.image = loadedImage
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                Logger.shared.error("Failed to load image", error: error, category: "images")
            }
        }
    }
    
    private func cancelLoading() {
        isLoading = false
        // Cancel any ongoing network requests if needed
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let memoryWarning = Notification.Name("com.figrclub.memory_warning")
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
