//
//  AccessibilityManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import UIKit
import SwiftUI

// MARK: - Accessibility Manager
final class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    // MARK: - Configuration
    func configureAccessibility() {
        // No podemos setear buttonShapesEnabled directamente
        // Solo podemos leer el estado actual
        let buttonShapesEnabled = UIAccessibility.buttonShapesEnabled
        Logger.shared.info("Button shapes enabled: \(buttonShapesEnabled)", category: "accessibility")
        
        // Verificar si VoiceOver está activo
        if UIAccessibility.isVoiceOverRunning {
            Logger.shared.info("VoiceOver is running", category: "accessibility")
            setupVoiceOverNotifications()
        }
        
        // Verificar otras configuraciones de accesibilidad
        checkAccessibilitySettings()
    }
    
    // MARK: - VoiceOver Support
    private func setupVoiceOverNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func voiceOverStatusChanged() {
        let isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        Logger.shared.info("VoiceOver status changed: \(isVoiceOverRunning)", category: "accessibility")
        
        // Notificar a la app del cambio
        NotificationCenter.default.post(
            name: Notification.Name("VoiceOverStatusChanged"),
            object: nil,
            userInfo: ["isRunning": isVoiceOverRunning]
        )
    }
    
    // MARK: - Accessibility Settings
    private func checkAccessibilitySettings() {
        // Verificar configuraciones de accesibilidad
        let settings = AccessibilitySettings(
            isVoiceOverRunning: UIAccessibility.isVoiceOverRunning,
            isSwitchControlRunning: UIAccessibility.isSwitchControlRunning,
            isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            isReduceTransparencyEnabled: UIAccessibility.isReduceTransparencyEnabled,
            isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled,
            isBoldTextEnabled: UIAccessibility.isBoldTextEnabled,
            buttonShapesEnabled: UIAccessibility.buttonShapesEnabled,
            prefersCrossFadeTransitions: UIAccessibility.prefersCrossFadeTransitions,
            isVideoAutoplayEnabled: UIAccessibility.isVideoAutoplayEnabled,
            isClosedCaptioningEnabled: UIAccessibility.isClosedCaptioningEnabled,
            isGuidedAccessEnabled: UIAccessibility.isGuidedAccessEnabled
        )
        
        // Log current settings
        Logger.shared.info("Accessibility settings: \(settings)", category: "accessibility")
        
        // Configurar la app según las preferencias
        applyAccessibilitySettings(settings)
    }
    
    // MARK: - Apply Settings
    private func applyAccessibilitySettings(_ settings: AccessibilitySettings) {
        // Aplicar configuraciones según las preferencias del usuario
        if settings.isReduceMotionEnabled {
            // Reducir o eliminar animaciones
            UIView.setAnimationsEnabled(false)
        }
        
        if settings.prefersCrossFadeTransitions {
            // Usar transiciones de desvanecimiento en lugar de otras animaciones
            CATransaction.setDisableActions(true)
        }
    }
    
    // MARK: - Accessibility Announcements
    func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: priority, argument: message)
        }
    }
    
    func announceScreenChange(_ screenName: String) {
        announce("Navegando a \(screenName)", priority: .screenChanged)
    }
    
    func announceLayoutChange(_ change: String) {
        announce(change, priority: .layoutChanged)
    }
}

// MARK: - Accessibility Settings Model
struct AccessibilitySettings {
    let isVoiceOverRunning: Bool
    let isSwitchControlRunning: Bool
    let isReduceMotionEnabled: Bool
    let isReduceTransparencyEnabled: Bool
    let isDarkerSystemColorsEnabled: Bool
    let isBoldTextEnabled: Bool
    let buttonShapesEnabled: Bool
    let prefersCrossFadeTransitions: Bool
    let isVideoAutoplayEnabled: Bool
    let isClosedCaptioningEnabled: Bool
    let isGuidedAccessEnabled: Bool
}

// MARK: - SwiftUI Accessibility Extensions
extension View {
    func accessibilityAnnouncement(_ message: String) -> some View {
        self.onAppear {
            AccessibilityManager.shared.announce(message)
        }
    }
    
    func accessibilityScreenChange(_ screenName: String) -> some View {
        self.onAppear {
            AccessibilityManager.shared.announceScreenChange(screenName)
        }
    }
}
