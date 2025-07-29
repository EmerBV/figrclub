//
//  CreateFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI
import Kingfisher

// MARK: - Content Creation Types
enum CreationContentType: String, CaseIterable, Identifiable {
    case publicacion = "PUBLICACIÓN"
    case historia = "HISTORIA"
    case reel = "REEL"
    case enDirecto = "EN DIRECTO"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
}

// MARK: - Create Flow View
struct CreateFlowView: View {
    let user: User
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    @State private var selectedContentType: CreationContentType = .publicacion
    @State private var showingImagePicker = false
    @State private var flashMode: FlashMode = .off
    @State private var isRecording = false
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    
    var body: some View {
        ZStack {
            // Camera background (full screen)
            cameraBackgroundView
            
            VStack(spacing: 0) {
                // Top section with close button and settings
                topNavigationSection
                
                // Side controls positioned higher
                HStack {
                    leftSideControls
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    rightSideControls
                        .padding(.trailing, 20)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Bottom area with capture button and selector
                bottomCaptureAndSelectorArea
            }
        }
        .ignoresSafeArea(.all) // Full screen, hiding tab bar completely
        .sheet(isPresented: $showingImagePicker) {
            ImageLibraryView()
        }
    }
    
    // MARK: - Camera Background
    private var cameraBackgroundView: some View {
        ZStack {
            // Simulated camera view
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea(.all)
            
            // Camera preview placeholder
            VStack {
                Spacer()
                
                Text("Vista de Cámara")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Integrar AVCaptureSession aquí")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
            }
        }
    }
    
    // MARK: - Top Navigation Section
    private var topNavigationSection: some View {
        HStack {
            // Close button
            Button(action: {
                // Close create flow and return to previous tab
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Title when in live mode
            if selectedContentType == .enDirecto {
                Text("¿Compartir con Seguidores?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Settings/options button
            Button(action: {
                // Show camera settings
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50) // Account for status bar
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.4),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Bottom Capture and Selector Area
    private var bottomCaptureAndSelectorArea: some View {
        VStack(spacing: 20) {
            // Center capture button (above the selector)
            centerCaptureButton
            
            // Bottom area with gallery, content selector, and flip camera
            HStack(alignment: .center, spacing: 0) {
                // Gallery button (left)
                Button(action: {
                    showingImagePicker = true
                }) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 80)
                
                Spacer()
                
                // Content type selector (center)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(CreationContentType.allCases) { contentType in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedContentType = contentType
                                }
                            }) {
                                Text(contentType.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedContentType == contentType ? .white : .white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                //.scrollClipDisabled()
                
                Spacer()
                
                // Camera flip button (right)
                Button(action: {
                    flipCamera()
                }) {
                    Circle()
                        .fill(Color.black)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 80)
                
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Safe area
        }
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Left Side Controls
    private var leftSideControls: some View {
        VStack(spacing: 24) {
            // Flash control
            Button(action: {
                cycleFlashMode()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: flashMode.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    if flashMode != .off {
                        Text(flashMode.title.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Speed control (for reels)
            if selectedContentType == .reel {
                Button(action: {
                    // Toggle speed
                }) {
                    VStack(spacing: 4) {
                        Text("1x")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("VELOCIDAD")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Timer (for stories)
            if selectedContentType == .historia {
                Button(action: {
                    // Set timer
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("15s")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Effects
            Button(action: {
                // Show effects
            }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Center Capture Button
    private var centerCaptureButton: some View {
        VStack(spacing: 12) {
            // Recording duration indicator
            if isRecording {
                Text(formatDuration(recordingDuration))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Main capture button
            Button(action: {
                handleCaptureAction()
            }) {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    // Inner button
                    Circle()
                        .fill(captureButtonColor)
                        .frame(width: captureButtonSize, height: captureButtonSize)
                        .scaleEffect(isRecording ? 0.7 : 1.0)
                    
                    // Live indicator
                    if selectedContentType == .enDirecto {
                        VStack {
                            Text("EN VIVO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .offset(y: -60)
                    }
                }
            }
            .scaleEffect(isRecording ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
    }
    
    // MARK: - Right Side Controls
    private var rightSideControls: some View {
        VStack(spacing: 24) {
            // Music (for reels and stories)
            if selectedContentType == .reel || selectedContentType == .historia {
                Button(action: {
                    // Add music
                }) {
                    Image(systemName: "music.note")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            // Additional effects or controls can go here
        }
    }
    
    // MARK: - Bottom Content Type Selector
    private var bottomContentTypeSelector: some View {
        VStack(spacing: 0) {
            // This section is now handled by bottomCaptureAndSelectorArea
            EmptyView()
        }
    }
}

// MARK: - Computed Properties
extension CreateFlowView {
    private var captureButtonColor: Color {
        switch selectedContentType {
        case .publicacion:
            return .white
        case .historia:
            return isRecording ? .red : .white
        case .reel:
            return isRecording ? .red : .white
        case .enDirecto:
            return .red
        }
    }
    
    private var captureButtonSize: CGFloat {
        isRecording ? 40 : 68
    }
}

// MARK: - Helper Methods
extension CreateFlowView {
    private func cycleFlashMode() {
        let allCases = FlashMode.allCases
        if let currentIndex = allCases.firstIndex(of: flashMode) {
            let nextIndex = (currentIndex + 1) % allCases.count
            flashMode = allCases[nextIndex]
        }
        HapticFeedbackManager.impact(.light)
    }
    
    private func flipCamera() {
        // Implement camera flip with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            // Toggle camera position
        }
        HapticFeedbackManager.impact(.medium)
    }
    
    private func handleCaptureAction() {
        switch selectedContentType {
        case .publicacion:
            capturePhoto()
        case .historia, .reel:
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        case .enDirecto:
            startLiveStream()
        }
    }
    
    private func capturePhoto() {
        HapticFeedbackManager.impact(.heavy)
        // TODO: Capture photo and navigate to edit screen
    }
    
    private func startRecording() {
        isRecording = true
        recordingDuration = 0
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            
            // Auto stop for stories after 15 seconds
            if selectedContentType == .historia && recordingDuration >= 15.0 {
                stopRecording()
            }
        }
        
        HapticFeedbackManager.impact(.heavy)
    }
    
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        HapticFeedbackManager.impact(.medium)
        // TODO: Navigate to edit screen with recorded content
    }
    
    private func startLiveStream() {
        HapticFeedbackManager.impact(.heavy)
        // TODO: Initialize live streaming
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Flash Mode Enum
enum FlashMode: CaseIterable {
    case off, on, auto
    
    var iconName: String {
        switch self {
        case .off: return "bolt.slash"
        case .on: return "bolt"
        case .auto: return "bolt.badge.a"
        }
    }
    
    var title: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        case .auto: return "Auto"
        }
    }
}

// MARK: - Image Library View
struct ImageLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Header similar to Instagram
                    HStack {
                        Button("Cancelar") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Recientes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Siguiente") {
                            // Process selected media
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Media grid placeholder
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                            ForEach(0..<20) { index in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.6))
                                    )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Haptic Feedback Manager
struct HapticFeedbackManager {
    enum FeedbackType {
        case light, medium, heavy
    }
    
    static func impact(_ type: FeedbackType) {
        let impactGenerator: UIImpactFeedbackGenerator
        
        switch type {
        case .light:
            impactGenerator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        }
        
        impactGenerator.impactOccurred()
    }
}
