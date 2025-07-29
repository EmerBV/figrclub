//
//  HapticFeedbackManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 29/7/25.
//

import UIKit
import SwiftUI

// MARK: - Haptic Feedback Manager Protocol
protocol HapticFeedbackManagerProtocol: ObservableObject {
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    func selection()
    
    // Context-specific methods
    func photoCapture()
    func recordingStart()
    func recordingStop()
    func cameraFlip()
    func flashModeChange()
    func zoom()
    func focus()
    func error()
    func success()
    func warning()
}

// MARK: - Haptic Feedback Manager Implementation
@MainActor
final class HapticFeedbackManager: ObservableObject, HapticFeedbackManagerProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var isEnabled = true
    @Published private(set) var lastFeedbackTime: Date?
    
    // MARK: - Properties
    private let deviceCapabilityChecker: DeviceCapabilityCheckerProtocol
    
    // MARK: - Initialization
    init(deviceCapabilityChecker: DeviceCapabilityCheckerProtocol = DeviceCapabilityChecker()) {
        self.deviceCapabilityChecker = deviceCapabilityChecker
        Logger.info("🎯 HapticFeedbackManager: Initialized")
    }
    
    // MARK: - Impact Feedback
    
    /// Proporciona feedback háptico de impacto
    /// - Parameter style: Estilo del impacto (light, medium, heavy)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard deviceCapabilityChecker.supportsHapticFeedback else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        updateLastFeedbackTime()
    }
    
    // MARK: - Notification Feedback
    
    /// Proporciona feedback háptico de notificación
    /// - Parameter type: Tipo de notificación (success, warning, error)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard deviceCapabilityChecker.supportsHapticFeedback else { return }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(type)
        
        updateLastFeedbackTime()
    }
    
    // MARK: - Selection Feedback
    
    /// Proporciona feedback háptico de selección
    func selection() {
        guard deviceCapabilityChecker.supportsHapticFeedback else { return }
        
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
        
        updateLastFeedbackTime()
    }
    
    // MARK: - Context-Specific Methods
    
    /// Feedback para captura de foto
    func photoCapture() {
        impact(.heavy)
    }
    
    /// Feedback para iniciar grabación
    func recordingStart() {
        impact(.heavy)
    }
    
    /// Feedback para detener grabación
    func recordingStop() {
        impact(.medium)
    }
    
    /// Feedback para cambio de cámara
    func cameraFlip() {
        impact(.medium)
    }
    
    /// Feedback para cambio de modo de flash
    func flashModeChange() {
        impact(.light)
    }
    
    /// Feedback para zoom
    func zoom() {
        impact(.light)
    }
    
    /// Feedback para enfoque
    func focus() {
        impact(.light)
    }
    
    /// Feedback para error
    func error() {
        notification(.error)
    }
    
    /// Feedback para éxito
    func success() {
        notification(.success)
    }
    
    /// Feedback para advertencia
    func warning() {
        notification(.warning)
    }
    
    // MARK: - Private Methods
    
    private func updateLastFeedbackTime() {
        lastFeedbackTime = Date()
    }
}

// MARK: - Device Capability Checker Protocol
protocol DeviceCapabilityCheckerProtocol {
    var supportsHapticFeedback: Bool { get }
}

// MARK: - Device Capability Checker Implementation
final class DeviceCapabilityChecker: DeviceCapabilityCheckerProtocol {
    var supportsHapticFeedback: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}
