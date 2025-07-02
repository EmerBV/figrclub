//
//  AccessibilitySupport.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import SwiftUI
import UIKit

// MARK: - Accessibility Helper
struct AccessibilityHelper {
    
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        return UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if Switch Control is running
    static var isSwitchControlRunning: Bool {
        return UIAccessibility.isSwitchControlRunning
    }
    
    /// Check if any assistive technology is running
    static var isAssistiveTechnologyRunning: Bool {
        return isVoiceOverRunning || isSwitchControlRunning
    }
    
    /// Post accessibility notification
    static func postNotification(_ notification: UIAccessibility.Notification, argument: Any? = nil) {
        UIAccessibility.post(notification: notification, argument: argument)
    }
    
    /// Announce message to screen reader
    static func announce(_ message: String) {
        postNotification(.announcement, argument: message)
    }
}

// MARK: - Accessibility Modifiers
extension View {
    
    /// Enhanced accessibility label with automatic fallback
    func accessibilityLabel(_ label: String?) -> some View {
        if let label = label, !label.isEmpty {
            return self.accessibilityLabel(label)
        }
        return self
    }
    
    /// Enhanced accessibility hint with automatic fallback
    func accessibilityHint(_ hint: String?) -> some View {
        if let hint = hint, !hint.isEmpty {
            return self.accessibilityHint(hint)
        }
        return self
    }
    
    /// Set accessibility identifier for UI testing
    func accessibilityIdentifier(_ identifier: String) -> some View {
        self.accessibilityIdentifier(identifier)
    }
    
    /// Mark as accessibility element with custom traits
    func accessibilityElement(
        children: AccessibilityChildBehavior = .ignore,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityElement(children: children)
            .accessibilityAddTraits(traits)
    }
    
    /// Semantic accessibility grouping
    func accessibilityGroup(
        label: String? = nil,
        hint: String? = nil,
        children: AccessibilityChildBehavior = .combine
    ) -> some View {
        Group {
            self
                .accessibilityElement(children: children)
                .accessibilityLabel(label)
                .accessibilityHint(hint)
        }
    }
}

// MARK: - Enhanced FigrButton with Accessibility
extension FigrButton {
    
    func accessibilityConfiguration(
        label: String? = nil,
        hint: String? = nil,
        identifier: String? = nil,
        traits: AccessibilityTraits = [.isButton]
    ) -> some View {
        self
            .accessibilityLabel(label ?? title)
            .accessibilityHint(hint)
            .accessibilityIdentifier(identifier ?? "button_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Enhanced FigrTextField with Accessibility
extension FigrTextField {
    
    func accessibilityConfiguration(
        label: String? = nil,
        hint: String? = nil,
        identifier: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label ?? title)
            .accessibilityHint(hint ?? placeholder)
            .accessibilityIdentifier(identifier ?? "textfield_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
            .accessibilityAddTraits([.isSearchField])
    }
}

// MARK: - Post Card Accessibility
extension PostCardView {
    
    func enhancedAccessibility() -> some View {
        self
            .accessibilityGroup(
                label: accessibilityPostLabel,
                hint: "Doble toque para ver detalles del post",
                children: .combine
            )
            .accessibilityIdentifier("post_card_\(post.id)")
            .accessibilityAction(.default) {
                // Handle post tap
            }
            .accessibilityAction(.magicTap) {
                // Quick like action
                if let isLiked = post.isLikedByCurrentUser {
                    let action = isLiked ? "quitado like" : "dado like"
                    AccessibilityHelper.announce("Has \(action) a este post")
                }
            }
    }
    
    private var accessibilityPostLabel: String {
        var components: [String] = []
        
        components.append("Post de \(post.userFullName)")
        
        if let content = post.content, !content.isEmpty {
            components.append(content)
        }
        
        if let imageUrls = post.imageUrls, !imageUrls.isEmpty {
            components.append("\(imageUrls.count) imagen\(imageUrls.count == 1 ? "" : "es")")
        }
        
        components.append("\(post.likesCount) me gusta")
        components.append("\(post.commentsCount) comentarios")
        
        if let isLiked = post.isLikedByCurrentUser {
            components.append(isLiked ? "Te gusta este post" : "No te gusta este post")
        }
        
        return components.joined(separator: ". ")
    }
}

// MARK: - Marketplace Item Accessibility
extension MarketplaceItemCard {
    
    func enhancedAccessibility() -> some View {
        self
            .accessibilityGroup(
                label: accessibilityItemLabel,
                hint: "Doble toque para ver detalles del producto",
                children: .combine
            )
            .accessibilityIdentifier("marketplace_item_\(item.id)")
            .accessibilityAddTraits([.isButton])
    }
    
    private var accessibilityItemLabel: String {
        var components: [String] = []
        
        components.append("Producto: \(item.title)")
        components.append("Precio: \(item.formattedPrice)")
        components.append("Condición: \(item.condition.displayName)")
        components.append("Vendedor: \(item.sellerName)")
        
        if let description = item.description, !description.isEmpty {
            components.append("Descripción: \(description)")
        }
        
        return components.joined(separator: ". ")
    }
}

// MARK: - Navigation Accessibility
extension TabView {
    
    func enhancedTabAccessibility() -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Navegación principal")
            .accessibilityHint("Desliza para cambiar entre pestañas")
    }
}

// MARK: - List Accessibility
extension LazyVStack {
    
    func enhancedListAccessibility(
        listName: String,
        itemCount: Int,
        loadingMore: Bool = false
    ) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(listName) con \(itemCount) elementos")
            .accessibilityHint(loadingMore ? "Cargando más elementos" : "Lista de \(listName)")
    }
}

// MARK: - Loading State Accessibility
extension View {
    
    func accessibilityLoadingState(_ isLoading: Bool, message: String = "Cargando") -> some View {
        self
            .accessibilityHidden(isLoading)
            .overlay(
                Group {
                    if isLoading {
                        Color.clear
                            .accessibilityElement()
                            .accessibilityLabel(message)
                            .accessibilityAddTraits([.updatesFrequently])
                    }
                }
            )
    }
}

// MARK: - Form Accessibility
extension Form {
    
    func enhancedFormAccessibility(
        title: String,
        isValid: Bool = true,
        errorMessage: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Formulario: \(title)")
            .accessibilityValue(isValid ? "Válido" : "Inválido")
            .accessibilityHint(errorMessage ?? (isValid ? "Formulario completado correctamente" : "Revisa los campos requeridos"))
    }
}

// MARK: - Image Accessibility
extension AsyncImage {
    
    func enhancedImageAccessibility(
        description: String? = nil,
        isDecorative: Bool = false
    ) -> some View {
        self
            .accessibilityElement()
            .accessibilityLabel(isDecorative ? "" : (description ?? "Imagen"))
            .accessibilityAddTraits(isDecorative ? [.isImage, .allowsDirectInteraction] : [.isImage])
            .accessibilityHidden(isDecorative)
    }
}

// MARK: - Alert Accessibility
extension View {
    
    func enhancedAlertAccessibility() -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits([.isModal])
            .onAppear {
                AccessibilityHelper.postNotification(.screenChanged)
            }
    }
}

// MARK: - Search Accessibility
extension SearchBar {
    
    func enhancedSearchAccessibility(
        resultsCount: Int? = nil
    ) -> some View {
        self
            .accessibilityLabel("Campo de búsqueda")
            .accessibilityHint("Ingresa términos para buscar")
            .accessibilityValue(resultsCount.map { "\($0) resultados encontrados" } ?? "")
            .accessibilityIdentifier("search_bar")
    }
}

// MARK: - Dynamic Type Support
extension View {
    
    /// Automatically scale for dynamic type
    func dynamicTypeSize(_ size: DynamicTypeSize) -> some View {
        self.dynamicTypeSize(size)
    }
    
    /// Limit dynamic type scaling with minimum and maximum sizes
    func dynamicTypeSize(
        _ size: DynamicTypeSize,
        minSize: DynamicTypeSize = .xSmall,
        maxSize: DynamicTypeSize = .accessibility3
    ) -> some View {
        self.dynamicTypeSize(size)
            .environment(\.dynamicTypeSize, max(minSize, min(maxSize, size)))
    }
}

// MARK: - Accessibility Announcements Manager
@MainActor
final class AccessibilityAnnouncementManager: ObservableObject {
    static let shared = AccessibilityAnnouncementManager()
    
    @Published var currentAnnouncement: String?
    
    private init() {}
    
    /// Announce a message with optional delay
    func announce(_ message: String, delay: TimeInterval = 0) {
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.performAnnouncement(message)
            }
        } else {
            performAnnouncement(message)
        }
    }
    
    /// Announce success message
    func announceSuccess(_ message: String) {
        announce("Éxito: \(message)")
    }
    
    /// Announce error message
    func announceError(_ message: String) {
        announce("Error: \(message)")
    }
    
    /// Announce loading state
    func announceLoading(_ message: String = "Cargando") {
        announce(message)
    }
    
    /// Announce navigation change
    func announceNavigation(_ screenName: String) {
        announce("Navegando a \(screenName)")
    }
    
    private func performAnnouncement(_ message: String) {
        currentAnnouncement = message
        AccessibilityHelper.announce(message)
        
        // Clear announcement after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.currentAnnouncement = nil
        }
    }
}

// MARK: - Accessibility Testing Helpers
#if DEBUG
struct AccessibilityTestingView: View {
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            List(testResults, id: \.self) { result in
                Text(result)
                    .font(.caption)
            }
            .navigationTitle("Accessibility Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Run Tests") {
                        runAccessibilityTests()
                    }
                }
            }
        }
    }
    
    private func runAccessibilityTests() {
        testResults.removeAll()
        
        // Test VoiceOver support
        testResults.append("VoiceOver Running: \(AccessibilityHelper.isVoiceOverRunning)")
        testResults.append("Switch Control Running: \(AccessibilityHelper.isSwitchControlRunning)")
        
        // Test dynamic type
        let currentTypeSize = UIApplication.shared.preferredContentSizeCategory
        testResults.append("Current Dynamic Type: \(currentTypeSize.rawValue)")
        
        // Test contrast ratios (simplified)
        testResults.append("High Contrast: \(UIAccessibility.isDarkerSystemColorsEnabled)")
        testResults.append("Reduce Motion: \(UIAccessibility.isReduceMotionEnabled)")
        testResults.append("Reduce Transparency: \(UIAccessibility.isReduceTransparencyEnabled)")
        
        AccessibilityHelper.announce("Pruebas de accesibilidad completadas")
    }
}
#endif

// MARK: - Color Accessibility Extensions
extension Color {
    
    /// Check if color has sufficient contrast with background
    func hassufficientContrast(with background: Color, for textSize: Font.TextStyle = .body) -> Bool {
        // Simplified contrast checking - in production, use proper contrast calculation
        // This would typically involve converting to luminance values and calculating contrast ratio
        return true // Placeholder implementation
    }
    
    /// Get accessible version of color
    func accessibleVariant(for background: Color) -> Color {
        // Return high contrast version if needed
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return self.opacity(0.9) // Simplified implementation
        }
        return self
    }
}

// MARK: - Haptic Feedback for Accessibility
extension View {
    
    /// Add haptic feedback for accessibility
    func accessibilityHapticFeedback(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        trigger: Bool
    ) -> some View {
        self
            .onChange(of: trigger) { _ in
                if AccessibilityHelper.isAssistiveTechnologyRunning {
                    let impactFeedback = UIImpactFeedbackGenerator(style: style)
                    impactFeedback.impactOccurred()
                }
            }
    }
}

// MARK: - Accessibility Settings View
struct AccessibilitySettingsView: View {
    @AppStorage("accessibility_announcements_enabled") private var announcementsEnabled = true
    @AppStorage("accessibility_haptic_enabled") private var hapticEnabled = true
    @AppStorage("accessibility_high_contrast") private var highContrastEnabled = false
    
    var body: some View {
        Form {
            Section("Configuración de Accesibilidad") {
                Toggle("Anuncios de VoiceOver", isOn: $announcementsEnabled)
                    .accessibilityHint("Habilita o deshabilita los anuncios automáticos")
                
                Toggle("Retroalimentación Háptica", isOn: $hapticEnabled)
                    .accessibilityHint("Habilita vibración para acciones importantes")
                
                Toggle("Alto Contraste", isOn: $highContrastEnabled)
                    .accessibilityHint("Mejora el contraste de colores")
            }
            
            Section("Información del Sistema") {
                HStack {
                    Text("VoiceOver")
                    Spacer()
                    Text(AccessibilityHelper.isVoiceOverRunning ? "Activo" : "Inactivo")
                        .foregroundColor(AccessibilityHelper.isVoiceOverRunning ? .green : .gray)
                }
                
                HStack {
                    Text("Switch Control")
                    Spacer()
                    Text(AccessibilityHelper.isSwitchControlRunning ? "Activo" : "Inactivo")
                        .foregroundColor(AccessibilityHelper.isSwitchControlRunning ? .green : .gray)
                }
            }
        }
        .navigationTitle("Accesibilidad")
        .navigationBarTitleDisplayMode(.inline)
    }
}
