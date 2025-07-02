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
    @EnvironmentObject private var remoteConfigManager: RemoteConfigManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.large) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 60))
                    .foregroundColor(.figrPrimary)
                
                Text("Mantenimiento")
                    .font(.figrTitle2.weight(.bold))
                    .foregroundColor(.white)
                
                Text(remoteConfigManager.getSetting("maintenance_message", defaultValue: "Estamos realizando mantenimiento programado."))
                    .font(.figrBody)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Reintentar") {
                    remoteConfigManager.loadRemoteConfig()
                }
                .buttonStyle(FilledButtonStyle())
            }
            .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Modo mantenimiento activo")
    }
}

// MARK: - Performance Overlay (Debug)
#if DEBUG
struct PerformanceOverlayView: View {
    @State private var memoryUsage: String = ""
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("MEM: \(memoryUsage)")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
        }
        .padding()
        .onAppear {
            startMemoryMonitoring()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startMemoryMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let usage = MemoryManager.shared.getCurrentMemoryUsage()
            memoryUsage = ByteCountFormatter.string(fromByteCount: Int64(usage), countStyle: .memory)
        }
    }
}
#endif

// MARK: - Button Styles
struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.figrPrimary)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
