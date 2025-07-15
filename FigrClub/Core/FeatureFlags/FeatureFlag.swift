//
//  FeatureFlag.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Feature Flag Model
struct FeatureFlag: Codable, Equatable, Identifiable {
    let id: String
    let value: Int
    let lastUpdated: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, value, lastUpdated
    }
    
    init(id: String, value: Int, lastUpdated: Date? = nil) {
        self.id = id
        self.value = value
        self.lastUpdated = lastUpdated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        value = try container.decode(Int.self, forKey: .value)
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated)
    }
    
    /// Indica si la feature está activa
    var isEnabled: Bool {
        return value == 1
    }
    
    /// Indica si la feature está desactivada
    var isDisabled: Bool {
        return value == 0
    }
    
    /// Obtener valor como booleano
    var boolValue: Bool {
        return isEnabled
    }
}

// MARK: - Feature Flags Response
struct FeatureFlagsResponse: Codable {
    let flags: [String: Int]
    let version: String?
    let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case flags, version, lastUpdated
    }
    
    /// Convierte el diccionario a array de FeatureFlag
    func toFeatureFlags() -> [FeatureFlag] {
        return flags.map { key, value in
            let lastUpdated = self.lastUpdated.flatMap {
                DateFormatter.iso8601.date(from: $0)
            }
            return FeatureFlag(id: key, value: value, lastUpdated: lastUpdated)
        }
    }
}

// MARK: - Feature Flag Keys (Enum para type safety)
enum FeatureFlagKey: String, CaseIterable {
    // Authentication Features
    case biometricAuth = "biometric_auth"
    case socialLogin = "social_login"
    case emailVerification = "email_verification"
    
    // Feed Features
    case infiniteScrollFeed = "infinite_scroll_feed"
    case videoPlayback = "video_playback"
    case liveStreaming = "live_streaming"
    case stories = "stories"
    
    // Marketplace Features
    case marketplace = "marketplace"
    case inAppPurchases = "in_app_purchases"
    case paymentIntegration = "payment_integration"
    case shippingCalculator = "shipping_calculator"
    
    // Social Features
    case comments = "comments"
    case likes = "likes"
    case follows = "follows"
    case directMessages = "direct_messages"
    case notifications = "notifications"
    
    // Profile Features
    case profileVerification = "profile_verification"
    case profileCustomization = "profile_customization"
    case privacySettings = "privacy_settings"
    
    // Create Features
    case postCreation = "post_creation"
    case imageFilters = "image_filters"
    case multipleImageUpload = "multiple_image_upload"
    case videoUpload = "video_upload"
    
    // Search Features
    case advancedSearch = "advanced_search"
    case searchHistory = "search_history"
    case searchSuggestions = "search_suggestions"
    
    // System Features
    case analytics = "analytics"
    case crashReporting = "crash_reporting"
    case performanceMonitoring = "performance_monitoring"
    
    // UI Features
    case darkMode = "dark_mode"
    case customThemes = "custom_themes"
    case newDesign = "new_design"
    
    // Beta Features
    case betaFeature1 = "beta_feature_1"
    case betaFeature2 = "beta_feature_2"
    case experimentalUI = "experimental_ui"
    
    // Payment Features
    case paypalPayment = "paypal_payment"
    
    // Branding
    case appLogo = "app_logo"
    
    /// Default value para cada feature flag
    var defaultValue: Int {
        switch self {
            // Features críticas siempre habilitadas por defecto
        case .emailVerification, .crashReporting, .analytics, .performanceMonitoring:
            return 1
            
            // Features básicas habilitadas por defecto
        case .infiniteScrollFeed, .stories, .marketplace, .comments, .likes, .follows:
            return 1
            
        case .notifications, .profileCustomization, .privacySettings, .postCreation:
            return 1
            
        case .multipleImageUpload, .searchHistory, .searchSuggestions, .darkMode:
            return 1
            
            // Features experimentales deshabilitadas por defecto
        case .betaFeature1, .betaFeature2, .experimentalUI, .newDesign:
            return 0
            
            // Features premium/pagadas deshabilitadas por defecto
        case .paypalPayment, .customThemes, .liveStreaming, .videoUpload:
            return 0
            
            // Features opcionales
        case .socialLogin, .biometricAuth, .videoPlayback, .inAppPurchases:
            return 0
            
        case .paymentIntegration, .shippingCalculator, .directMessages, .profileVerification:
            return 0
            
        case .imageFilters, .advancedSearch, .appLogo:
            return 0
        }
    }
    
    /// Descripción legible de la feature flag
    var description: String {
        switch self {
        case .biometricAuth:
            return "Autenticación biométrica (Face ID/Touch ID)"
        case .socialLogin:
            return "Inicio de sesión con redes sociales"
        case .emailVerification:
            return "Verificación de email obligatoria"
        case .infiniteScrollFeed:
            return "Scroll infinito en el feed"
        case .videoPlayback:
            return "Reproducción de videos"
        case .liveStreaming:
            return "Transmisiones en vivo"
        case .stories:
            return "Historias temporales"
        case .marketplace:
            return "Marketplace de productos"
        case .inAppPurchases:
            return "Compras dentro de la app"
        case .paymentIntegration:
            return "Integración de pagos"
        case .shippingCalculator:
            return "Calculadora de envíos"
        case .comments:
            return "Sistema de comentarios"
        case .likes:
            return "Sistema de likes"
        case .follows:
            return "Sistema de seguimiento"
        case .directMessages:
            return "Mensajes directos"
        case .notifications:
            return "Notificaciones push"
        case .profileVerification:
            return "Verificación de perfiles"
        case .profileCustomization:
            return "Personalización de perfil"
        case .privacySettings:
            return "Configuración de privacidad"
        case .postCreation:
            return "Creación de posts"
        case .imageFilters:
            return "Filtros de imágenes"
        case .multipleImageUpload:
            return "Subida múltiple de imágenes"
        case .videoUpload:
            return "Subida de videos"
        case .advancedSearch:
            return "Búsqueda avanzada"
        case .searchHistory:
            return "Historial de búsquedas"
        case .searchSuggestions:
            return "Sugerencias de búsqueda"
        case .analytics:
            return "Analytics y métricas"
        case .crashReporting:
            return "Reporte de crashes"
        case .performanceMonitoring:
            return "Monitoreo de rendimiento"
        case .darkMode:
            return "Modo oscuro"
        case .customThemes:
            return "Temas personalizados"
        case .newDesign:
            return "Nuevo diseño de UI"
        case .betaFeature1:
            return "Feature Beta 1"
        case .betaFeature2:
            return "Feature Beta 2"
        case .experimentalUI:
            return "UI experimental"
        case .paypalPayment:
            return "Pagos con PayPal"
        case .appLogo:
            return "Logo personalizado de la app"
        }
    }
    
    /// Categoría de la feature flag
    var category: FeatureFlagCategory {
        switch self {
        case .biometricAuth, .socialLogin, .emailVerification:
            return .authentication
        case .infiniteScrollFeed, .videoPlayback, .liveStreaming, .stories:
            return .feed
        case .marketplace, .inAppPurchases, .paymentIntegration, .shippingCalculator, .paypalPayment:
            return .marketplace
        case .comments, .likes, .follows, .directMessages:
            return .social
        case .notifications:
            return .notifications
        case .profileVerification, .profileCustomization, .privacySettings:
            return .profile
        case .postCreation, .imageFilters, .multipleImageUpload, .videoUpload:
            return .creation
        case .advancedSearch, .searchHistory, .searchSuggestions:
            return .search
        case .analytics, .crashReporting, .performanceMonitoring:
            return .system
        case .darkMode, .customThemes, .newDesign, .appLogo:
            return .ui
        case .betaFeature1, .betaFeature2, .experimentalUI:
            return .experimental
        }
    }
}

// MARK: - Feature Flag Categories
enum FeatureFlagCategory: String, CaseIterable {
    case authentication = "Authentication"
    case feed = "Feed"
    case marketplace = "Marketplace"
    case social = "Social"
    case notifications = "Notifications"
    case profile = "Profile"
    case creation = "Creation"
    case search = "Search"
    case system = "System"
    case ui = "UI"
    case experimental = "Experimental"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .authentication:
            return "person.badge.key"
        case .feed:
            return "list.dash"
        case .marketplace:
            return "storefront"
        case .social:
            return "person.2"
        case .notifications:
            return "bell"
        case .profile:
            return "person.circle"
        case .creation:
            return "plus.app"
        case .search:
            return "magnifyingglass"
        case .system:
            return "gear"
        case .ui:
            return "paintbrush"
        case .experimental:
            return "flask"
        }
    }
}

// MARK: - Feature Flag Error Types
enum FeatureFlagError: Error, LocalizedError {
    case networkError(Error)
    case parsingError(String)
    case invalidURL
    case noDataReceived
    case storageError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Error al parsear datos: \(message)"
        case .invalidURL:
            return "URL inválida para feature flags"
        case .noDataReceived:
            return "No se recibieron datos del servidor"
        case .storageError(let message):
            return "Error de almacenamiento: \(message)"
        }
    }
}
