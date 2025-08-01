//
//  CreateFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI
import Kingfisher
import AVFoundation
import Photos

// MARK: - Content Creation Types
enum CreationContentType: CaseIterable {
    case post
    case story
    case reel
    case liveStream
    
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .post: return .createPost
        case .story: return .createStory
        case .reel: return .createReel
        case .liveStream: return .createLiveStream
        }
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
    
    var cameraFlashMode: CameraFlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

// MARK: - Create Flow View
struct CreateFlowView: View {
    let user: User
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    // Injected Dependencies
    @EnvironmentObject private var cameraManager: CameraManager
    @EnvironmentObject private var hapticManager: HapticFeedbackManager
    
    // UI State
    @State private var selectedContentType: CreationContentType = .post
    @State private var showingImagePicker = false
    @State private var flashMode: FlashMode = .off
    @State private var isRecording = false
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    @State private var showingCapturedMedia = false
    @State private var capturedImage: UIImage?
    @State private var capturedVideoURL: URL?
    @State private var showingPermissionAlert = false
    @State private var currentZoom: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Camera background
            cameraBackgroundView
            
            VStack(spacing: AppTheme.Spacing.xLarge) {
                // Top section with close button and settings
                topNavigationSection
                
                // Side controls positioned higher
                HStack {
                    leftSideControls
                    
                    Spacer()
                    
                    rightSideControls
                    
                }
                .padding(.top, AppTheme.Spacing.xxxLarge)
                .padding(.leading, AppTheme.Spacing.large)
                .padding(.trailing, AppTheme.Spacing.large)
                
                Spacer()
                
                // Bottom area with capture button and selector
                bottomCaptureAndSelectorArea
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImageLibraryView()
        }
        .sheet(isPresented: $showingCapturedMedia) {
            if let image = capturedImage {
                MediaEditView(image: image, user: user)
            } else if let videoURL = capturedVideoURL {
                MediaEditView(videoURL: videoURL, user: user)
            }
        }
        .alert(localizationManager.localizedString(for: .cameraPermissionRequired), isPresented: $showingPermissionAlert) {
            Button(localizationManager.localizedString(for: .goToSettings)) {
                openAppSettings()
            }
            Button(localizationManager.localizedString(for: .cancel), role: .cancel) {
                navigationCoordinator.dismissCreatePost()
            }
        } message: {
            Text(localizationManager.localizedString(for: .cameraPermissionSettingsDescription))
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            Task {
                await cameraManager.stopSession()
            }
        }
        .onChange(of: cameraManager.isRecording) { oldValue, newValue in
            isRecording = newValue
        }
        .onChange(of: cameraManager.recordingDuration) { oldValue, newValue in
            recordingDuration = newValue
        }
        .onChange(of: flashMode) { oldValue, newValue in
            cameraManager.setFlashMode(newValue.cameraFlashMode)
        }
    }
    
    // MARK: - Camera Background
    private var cameraBackgroundView: some View {
        ZStack {
            if cameraManager.isConfigured && cameraManager.permissionGranted {
                CameraPreviewView(
                    previewLayer: cameraManager.getPreviewLayer(),
                    onTap: { point in
                        Task {
                            await cameraManager.focusAt(point)
                        }
                    },
                    onPinch: { zoomFactor in
                        let newZoom = currentZoom * zoomFactor
                        Task {
                            await cameraManager.setZoom(newZoom)
                            await MainActor.run {
                                currentZoom = newZoom
                            }
                        }
                    }
                )
                .ignoresSafeArea(.all)
                
                // Zoom indicator
                if currentZoom > 1.0 {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(String(format: "%.1f", currentZoom))x")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.trailing, 20)
                                .padding(.top, 100)
                        }
                        Spacer()
                    }
                }
            } else {
                // Fallback black view
                Rectangle()
                    .fill(Color.black)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 16) {
                    if !cameraManager.permissionGranted {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(localizationManager.localizedString(for: .cameraPermissionRequired))
                            .font(.title2.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text(localizationManager.localizedString(for: .tapToAllowCameraPermission))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text(localizationManager.localizedString(for: .settingUpCamera))
                            .font(.title2.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .onTapGesture {
                    if !cameraManager.permissionGranted {
                        showingPermissionAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - Top Navigation Section
    private var topNavigationSection: some View {
        HStack {
            // Close button
            Button(action: {
                navigationCoordinator.dismissCreatePost()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Title when in live mode
            if selectedContentType == .liveStream {
                Text(localizationManager.localizedString(for: .shareWithFollowers))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Settings/options button
            Button(action: {
                // Show camera settings
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.large)
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
                    }
                }
            }
            
            // Timer (for stories)
            if selectedContentType == .story {
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
    
    // MARK: - Right Side Controls
    private var rightSideControls: some View {
        VStack(spacing: 24) {
            // Music (for reels and stories)
            if selectedContentType == .reel || selectedContentType == .story {
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
                FigrHorizontalScrollView {
                    HStack(spacing: 20) {
                        ForEach(CreationContentType.allCases, id: \.self) { contentType in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedContentType = contentType
                                }
                            }) {
                                Text(localizationManager.localizedString(for: contentType.localizedStringKey))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedContentType == contentType ? .white : .white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                
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
                    if selectedContentType == .liveStream {
                        VStack {
                            Text(localizationManager.localizedString(for: .createLiveStream))
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
}

// MARK: - Computed Properties
extension CreateFlowView {
    private var captureButtonColor: Color {
        switch selectedContentType {
        case .post:
            return .white
        case .story:
            return isRecording ? .red : .white
        case .reel:
            return isRecording ? .red : .white
        case .liveStream:
            return .red
        }
    }
    
    private var captureButtonSize: CGFloat {
        isRecording ? 40 : 68
    }
}

// MARK: - Helper Methods
extension CreateFlowView {
    private func setupCamera() {
        cameraManager.delegate = self
        
        Task {
            await cameraManager.startSession()
        }
    }
    
    private func cycleFlashMode() {
        let allCases = FlashMode.allCases
        if let currentIndex = allCases.firstIndex(of: flashMode) {
            let nextIndex = (currentIndex + 1) % allCases.count
            flashMode = allCases[nextIndex]
        }
        hapticManager.flashModeChange()
    }
    
    private func flipCamera() {
        Task {
            do {
                try await cameraManager.flipCamera()
                hapticManager.cameraFlip()
            } catch {
                Logger.error("Failed to flip camera: \(error)")
            }
        }
    }
    
    private func handleCaptureAction() {
        switch selectedContentType {
        case .post:
            capturePhoto()
        case .story, .reel:
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        case .liveStream:
            startLiveStream()
        }
    }
    
    private func capturePhoto() {
        Task {
            do {
                try await cameraManager.capturePhoto()
                hapticManager.photoCapture()
            } catch {
                Logger.error("Failed to capture photo: \(error)")
            }
        }
    }
    
    private func startRecording() {
        Task {
            do {
                try await cameraManager.startVideoRecording()
                hapticManager.recordingStart()
            } catch {
                Logger.error("Failed to start recording: \(error)")
            }
        }
    }
    
    private func stopRecording() {
        cameraManager.stopVideoRecording()
        hapticManager.recordingStop()
    }
    
    private func startLiveStream() {
        hapticManager.impact(.heavy)
        // TODO: Initialize live streaming
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
}

// MARK: - CameraManagerDelegate
extension CreateFlowView: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didCapturePhoto image: UIImage) {
        Task { @MainActor in
            capturedImage = image
            capturedVideoURL = nil
            showingCapturedMedia = true
        }
    }
    
    func cameraManager(_ manager: CameraManager, didStartRecording url: URL) {
        Logger.info("Started recording video")
    }
    
    func cameraManager(_ manager: CameraManager, didFinishRecording url: URL) {
        Task { @MainActor in
            capturedVideoURL = url
            capturedImage = nil
            showingCapturedMedia = true
        }
    }
    
    func cameraManager(_ manager: CameraManager, didFailWithError error: CameraError) {
        Task { @MainActor in
            Logger.error("Camera error: \(error.localizedDescription)")
            
            switch error {
            case .notAuthorized:
                showingPermissionAlert = true
            default:
                // Handle other errors - could show toast or alert
                break
            }
        }
    }
    
    func cameraManager(_ manager: CameraManager, didUpdateRecordingDuration duration: TimeInterval) {
        // Recording duration is already observed via @Published property
        
        // Auto stop for stories after 15 seconds
        if selectedContentType == .story && duration >= 15.0 {
            stopRecording()
        }
        
        // Auto stop for reels after 60 seconds
        if selectedContentType == .reel && duration >= 60.0 {
            stopRecording()
        }
    }
}

// MARK: - Media Edit View
struct MediaEditView: View {
    let image: UIImage?
    let videoURL: URL?
    let user: User
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    init(image: UIImage, user: User) {
        self.image = image
        self.videoURL = nil
        self.user = user
    }
    
    init(videoURL: URL, user: User) {
        self.image = nil
        self.videoURL = videoURL
        self.user = user
    }
    
    var body: some View {
        FigrNavigationStack {
            VStack {
                // Preview area
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let videoURL = videoURL {
                    // Video player would go here
                    VStack {
                        Spacer()
                        Text(localizationManager.localizedString(for: .createLiveStream))
                            .foregroundColor(.white)
                            .font(.title2)
                        Text(videoURL.lastPathComponent)
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                        Spacer()
                    }
                }
                
                // Bottom controls
                HStack {
                    Button(localizationManager.localizedString(for: .cancel)) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(localizationManager.localizedString(for: .next)) {
                        // Process and save media
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Image Library View
struct ImageLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        FigrNavigationStack {
            VStack {
                HStack {
                    Button(localizationManager.localizedString(for: .cancel)) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(localizationManager.localizedString(for: .recentString))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(localizationManager.localizedString(for: .next)) {
                        // Handle selection
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding()
                
                Spacer()
                
                // Photo library grid would go here
                Text(localizationManager.localizedString(for: .photoGallery))
                    .foregroundColor(.white.opacity(0.6))
                    .font(.title2)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}
