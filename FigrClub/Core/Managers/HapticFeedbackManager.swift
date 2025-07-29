//
//  HapticFeedbackManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 29/7/25.
//

import UIKit

// MARK: - Protocol Definition

/// Protocolo para gestión centralizada de feedback háptico
protocol HapticFeedbackServiceProtocol {
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

// MARK: - Service Implementation

/// Gestor centralizado para feedback háptico siguiendo las Human Interface Guidelines
final class HapticFeedbackService: HapticFeedbackServiceProtocol {
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Impact Feedback
    
    /// Proporciona feedback háptico de impacto
    /// - Parameter style: Estilo del impacto (light, medium, heavy)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Proporciona feedback háptico de notificación
    /// - Parameter type: Tipo de notificación (success, warning, error)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(type)
    }
    
    // MARK: - Selection Feedback
    
    /// Proporciona feedback háptico de selección
    func selection() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
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
}

// MARK: - Legacy Support

/// Clase legacy para mantener compatibilidad temporal
/// @deprecated Usar HapticFeedbackServiceProtocol con inyección de dependencias
final class HapticFeedbackManager {
    private static let service = HapticFeedbackService()
    
    @available(*, deprecated, message: "Usar HapticFeedbackServiceProtocol con inyección de dependencias")
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        service.impact(style)
    }
    
    @available(*, deprecated, message: "Usar HapticFeedbackServiceProtocol con inyección de dependencias")
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        service.notification(type)
    }
    
    @available(*, deprecated, message: "Usar HapticFeedbackServiceProtocol con inyección de dependencias")
    static func selection() {
        service.selection()
    }
}
