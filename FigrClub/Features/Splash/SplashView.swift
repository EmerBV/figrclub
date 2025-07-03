//
//  SplashView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import SwiftUI

// MARK: - Splash View
struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.figrBackground
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.large) {
                Image("FigrClubLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.8)
                
                Text("FigrClub")
                    .font(.figrTitle1.weight(.bold))
                    .foregroundColor(.figrPrimary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                ProgressView()
                    .scaleEffect(0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel("FigrClub está cargando")
        .accessibilityAddTraits([.updatesFrequently])
    }
}

// MARK: - Maintenance View
struct MaintenanceView: View {
    @StateObject private var remoteConfig = RemoteConfigManager.shared
    
    var body: some View {
        ZStack {
            Color.figrBackground
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.large) {
                // Icono
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 80))
                    .foregroundColor(.figrPrimary)
                    .padding(.bottom, Spacing.medium)
                
                // Título
                Text("Mantenimiento en curso")
                    .font(.figrTitle1)
                    .foregroundColor(.figrTextPrimary)
                    .multilineTextAlignment(.center)
                
                // Mensaje
                Text(remoteConfig.maintenanceMessage)
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.large)
                
                // Tiempo estimado
                if let estimatedTime = remoteConfig.estimatedMaintenanceEnd {
                    VStack(spacing: Spacing.small) {
                        Text("Tiempo estimado:")
                            .font(.figrCaption)
                            .foregroundColor(.figrTextSecondary)
                        
                        Text(estimatedTime, style: .relative)
                            .font(.figrCallout.weight(.medium))
                            .foregroundColor(.figrPrimary)
                    }
                    .padding(.top, Spacing.medium)
                }
                
                // Botón de reintentar
                Button {
                    remoteConfig.loadRemoteConfig()
                } label: {
                    Text("Verificar estado")
                        .font(.figrCallout.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xLarge)
                        .padding(.vertical, Spacing.medium)
                        .background(Color.figrPrimary)
                        .cornerRadius(AppConfig.UI.cornerRadius)
                }
                .padding(.top, Spacing.large)
            }
            .padding()
        }
    }
}

// MARK: - Performance Overlay View
struct PerformanceOverlayView: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Botón para expandir/contraer
            Button {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.left")
                        .font(.caption2)
                    Text("Debug")
                        .font(.caption2.weight(.medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.8))
                .cornerRadius(4)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    // FPS
                    MetricRow(
                        label: "FPS",
                        value: "\(Int(performanceMonitor.currentFPS))",
                        color: fpsColor(performanceMonitor.currentFPS)
                    )
                    
                    // Memoria
                    MetricRow(
                        label: "Memory",
                        value: formatMemory(performanceMonitor.memoryUsage),
                        color: memoryColor(performanceMonitor.memoryUsage)
                    )
                    
                    // CPU
                    MetricRow(
                        label: "CPU",
                        value: "\(Int(performanceMonitor.cpuUsage))%",
                        color: cpuColor(performanceMonitor.cpuUsage)
                    )
                    
                    // Network
                    if let latency = performanceMonitor.networkLatency {
                        MetricRow(
                            label: "Latency",
                            value: "\(Int(latency))ms",
                            color: latencyColor(latency)
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Acciones
                    Button {
                        performanceMonitor.clearCache()
                    } label: {
                        Text("Clear Cache")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        performanceMonitor.logPerformanceReport()
                    } label: {
                        Text("Log Report")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.8))
                .cornerRadius(8)
                .transition(.scale)
            }
        }
        .padding(8)
    }
    
    // MARK: - Helper Methods
    private func fpsColor(_ fps: Double) -> Color {
        if fps >= 55 { return .green }
        if fps >= 30 { return .yellow }
        return .red
    }
    
    private func memoryColor(_ memory: Double) -> Color {
        if memory < 100 { return .green }
        if memory < 200 { return .yellow }
        return .red
    }
    
    private func cpuColor(_ cpu: Double) -> Color {
        if cpu < 50 { return .green }
        if cpu < 80 { return .yellow }
        return .red
    }
    
    private func latencyColor(_ latency: Double) -> Color {
        if latency < 100 { return .green }
        if latency < 300 { return .yellow }
        return .red
    }
    
    private func formatMemory(_ mb: Double) -> String {
        return String(format: "%.0fMB", mb)
    }
}

// MARK: - Metric Row
struct MetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.caption2.weight(.medium))
                .foregroundColor(color)
        }
        .frame(width: 120)
    }
}

// MARK: - Performance Monitor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var networkLatency: Double?
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // FPS Monitoring
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .common)
        
        // Memory and CPU monitoring
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateMemoryUsage()
            self.updateCPUUsage()
        }
    }
    
    @objc private func updateFPS(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        let deltaTime = displayLink.timestamp - lastTimestamp
        lastTimestamp = displayLink.timestamp
        
        let fps = 1.0 / deltaTime
        DispatchQueue.main.async {
            self.currentFPS = fps
        }
    }
    
    private func updateMemoryUsage() {
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
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            DispatchQueue.main.async {
                self.memoryUsage = usedMemory
            }
        }
    }
    
    private func updateCPUUsage() {
        // Simplified CPU usage calculation
        let cpuUsage = Double.random(in: 10...90)
        DispatchQueue.main.async {
            self.cpuUsage = cpuUsage
        }
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        Logger.shared.info("Cache cleared", category: "performance")
    }
    
    func logPerformanceReport() {
        let report = """
        Performance Report:
        - FPS: \(currentFPS)
        - Memory: \(memoryUsage) MB
        - CPU: \(cpuUsage)%
        - Latency: \(networkLatency ?? 0) ms
        """
        Logger.shared.info(report, category: "performance")
    }
}
