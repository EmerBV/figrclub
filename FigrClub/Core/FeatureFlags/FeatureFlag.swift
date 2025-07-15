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
    
    // Analytics Features
    case analytics = "analytics"
    case crashReporting = "crash_reporting"
    case performanceMonitoring = "performance_monitoring"
    
    // UI Features
    case darkMode = "dark_mode"
    case customThemes = "custom_themes"
    case newDesign = "new_design"
    
    // Experimental Features
    case beta_feature_1 = "beta_feature_1"
    case beta_feature_2 = "beta_feature_2"
    case experimental_ui = "experimental_ui"
    
    var defaultValue: Int {
        switch self {
            // Features enabled by default
        case .comments, .likes, .follows, .notifications, .postCreation:
            return 1
            // Features disabled by default
        default:
            return 0
        }
    }
    
    var description: String {
        switch self {
        case .biometricAuth:
            return "Autenticación biométrica (Touch ID/Face ID)"
        case .socialLogin:
            return "Login con redes sociales"
        case .emailVerification:
            return "Verificación por email"
        case .infiniteScrollFeed:
            return "Scroll infinito en el feed"
        case .videoPlayback:
            return "Reproducción de videos"
        case .liveStreaming:
            return "Transmisiones en vivo"
        case .stories:
            return "Historias (Stories)"
        case .marketplace:
            return "Marketplace de figuras"
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
            return "Sistema de follows"
        case .directMessages:
            return "Mensajes directos"
        case .notifications:
            return "Notificaciones push"
        case .profileVerification:
            return "Verificación de perfil"
        case .profileCustomization:
            return "Personalización de perfil"
        case .privacySettings:
            return "Configuración de privacidad"
        case .postCreation:
            return "Creación de posts"
        case .imageFilters:
            return "Filtros de imagen"
        case .multipleImageUpload:
            return "Subida múltiple de imágenes"
        case .videoUpload:
            return "Subida de videos"
        case .advancedSearch:
            return "Búsqueda avanzada"
        case .searchHistory:
            return "Historial de búsqueda"
        case .searchSuggestions:
            return "Sugerencias de búsqueda"
        case .analytics:
            return "Analytics"
        case .crashReporting:
            return "Reportes de crashes"
        case .performanceMonitoring:
            return "Monitoreo de rendimiento"
        case .darkMode:
            return "Modo oscuro"
        case .customThemes:
            return "Temas personalizados"
        case .newDesign:
            return "Nuevo diseño"
        case .beta_feature_1:
            return "Feature Beta 1"
        case .beta_feature_2:
            return "Feature Beta 2"
        case .experimental_ui:
            return "UI Experimental"
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

// MARK: - Feature Flag Configuration
struct FeatureFlagConfiguration {
    let remoteURL: String
    let fallbackFlags: [FeatureFlagKey: Int]
    let refreshInterval: TimeInterval
    let enableLocalStorage: Bool
    let enableBackgroundRefresh: Bool
    
    static let `default` = FeatureFlagConfiguration(
        remoteURL: "https://raw.githubusercontent.com/figrclub/feature-flags/main/flags.json",
        fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
        refreshInterval: 300, // 5 minutos
        enableLocalStorage: true,
        enableBackgroundRefresh: true
    )
    
    static let development = FeatureFlagConfiguration(
        remoteURL: "https://raw.githubusercontent.com/figrclub/feature-flags/develop/flags.json",
        fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, $0.defaultValue) }),
        refreshInterval: 60, // 1 minuto para desarrollo
        enableLocalStorage: true,
        enableBackgroundRefresh: true
    )
    
    static let testing = FeatureFlagConfiguration(
        remoteURL: "https://raw.githubusercontent.com/figrclub/feature-flags/test/flags.json",
        fallbackFlags: Dictionary(uniqueKeysWithValues: FeatureFlagKey.allCases.map { ($0, 1) }), // Todas activadas para testing
        refreshInterval: 30,
        enableLocalStorage: false,
        enableBackgroundRefresh: false
    )
}
