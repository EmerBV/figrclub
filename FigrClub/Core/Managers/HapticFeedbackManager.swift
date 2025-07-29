//
//  HapticFeedbackManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 29/7/25.
//

import UIKit

/// Gestor centralizado para feedback háptico siguiendo las Human Interface Guidelines
final class HapticFeedbackManager {
    
    // MARK: - Singleton
    static let shared = HapticFeedbackManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Proporciona feedback háptico de impacto
    /// - Parameter style: Estilo del impacto (light, medium, heavy)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Proporciona feedback háptico de notificación
    /// - Parameter type: Tipo de notificación (success, warning, error)
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(type)
    }
    
    // MARK: - Selection Feedback
    
    /// Proporciona feedback háptico de selección
    static func selection() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Context-Specific Methods
    
    /// Feedback para captura de foto
    static func photoCapture() {
        impact(.heavy)
    }
    
    /// Feedback para iniciar grabación
    static func recordingStart() {
        impact(.heavy)
    }
    
    /// Feedback para detener grabación
    static func recordingStop() {
        impact(.medium)
    }
    
    /// Feedback para cambio de cámara
    static func cameraFlip() {
        impact(.medium)
    }
    
    /// Feedback para cambio de modo de flash
    static func flashModeChange() {
        impact(.light)
    }
    
    /// Feedback para zoom
    static func zoom() {
        impact(.light)
    }
    
    /// Feedback para enfoque
    static func focus() {
        impact(.light)
    }
    
    /// Feedback para error
    static func error() {
        notification(.error)
    }
    
    /// Feedback para éxito
    static func success() {
        notification(.success)
    }
    
    /// Feedback para advertencia
    static func warning() {
        notification(.warning)
    }
}
