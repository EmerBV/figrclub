//
//  LocalizationManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Supported Languages
enum SupportedLanguage: String, CaseIterable {
    case spanish = "es"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .spanish:
            return "Español"
        case .english:
            return "English"
        }
    }
    
    var nativeName: String {
        switch self {
        case .spanish:
            return "Español"
        case .english:
            return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .spanish:
            return "🇪🇸"
        case .english:
            return "🇺🇸"
        }
    }
    
    var locale: Locale {
        return Locale(identifier: rawValue)
    }
}

// MARK: - Localization Manager Protocol
protocol LocalizationManagerProtocol: ObservableObject {
    var currentLanguage: SupportedLanguage { get }
    var isSystemLanguageDetected: Bool { get }
    
    func setLanguage(_ language: SupportedLanguage)
    func detectSystemLanguage() -> SupportedLanguage
    func localizedString(for key: LocalizedStringKey) -> String
    func localizedString(for key: LocalizedStringKey, arguments: CVarArg...) -> String
}

// MARK: - Localization Manager
@MainActor
final class LocalizationManager: ObservableObject, LocalizationManagerProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var currentLanguage: SupportedLanguage = .spanish
    @Published private(set) var isSystemLanguageDetected: Bool = false
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let userDefaultsKey = "selected_language"
    private let isFirstLaunchKey = "is_first_language_setup"
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        setupInitialLanguage()
        Logger.info("🌍 LocalizationManager: Initialized with language: \(currentLanguage.displayName)")
    }
    
    // MARK: - Public Methods
    
    func setLanguage(_ language: SupportedLanguage) {
        Logger.info("🌍 LocalizationManager: Changing language to: \(language.displayName)")
        
        currentLanguage = language
        saveLanguagePreference(language)
        
        // Notificar al sistema que el idioma ha cambiado
        NotificationCenter.default.post(
            name: .languageChanged,
            object: nil,
            userInfo: ["language": language.rawValue]
        )
        
        Logger.info("✅ LocalizationManager: Language changed successfully")
    }
    
    func detectSystemLanguage() -> SupportedLanguage {
        // Obtener los idiomas preferidos del sistema
        let preferredLanguages = Locale.preferredLanguages
        Logger.debug("🔍 LocalizationManager: System preferred languages: \(preferredLanguages)")
        
        // Buscar el primer idioma soportado en las preferencias del sistema
        for languageCode in preferredLanguages {
            let baseLanguageCode = String(languageCode.prefix(2))
            
            if let supportedLanguage = SupportedLanguage(rawValue: baseLanguageCode) {
                Logger.info("🎯 LocalizationManager: Detected system language: \(supportedLanguage.displayName)")
                return supportedLanguage
            }
        }
        
        // Si no se encuentra ningún idioma soportado, usar español como default
        Logger.info("⚠️ LocalizationManager: No supported system language found, defaulting to Spanish")
        return .spanish
    }
    
    func localizedString(for key: LocalizedStringKey) -> String {
        return localizedString(for: key, arguments: [])
    }
    
    func localizedString(for key: LocalizedStringKey, arguments: CVarArg...) -> String {
        let localizedString = NSLocalizedString(
            key.rawValue,
            tableName: "Localizable",
            bundle: .main,
            value: key.fallbackValue,
            comment: key.comment
        )
        
        if arguments.isEmpty {
            return localizedString
        } else {
            return String(format: localizedString, arguments: arguments)
        }
    }
    
    // MARK: - Language Management
    
    func getSupportedLanguages() -> [SupportedLanguage] {
        return SupportedLanguage.allCases
    }
    
    func getCurrentLocale() -> Locale {
        return currentLanguage.locale
    }
    
    func isLanguageSupported(_ languageCode: String) -> Bool {
        return SupportedLanguage(rawValue: languageCode) != nil
    }
    
    // MARK: - First Launch Detection
    
    var isFirstLanguageSetup: Bool {
        return !userDefaults.bool(forKey: isFirstLaunchKey)
    }
    
    func markLanguageSetupCompleted() {
        userDefaults.set(true, forKey: isFirstLaunchKey)
        Logger.info("✅ LocalizationManager: First language setup marked as completed")
    }
}

// MARK: - Private Methods
private extension LocalizationManager {
    
    func setupInitialLanguage() {
        if isFirstLanguageSetup {
            // Primera vez que se abre la app - detectar idioma del sistema
            let detectedLanguage = detectSystemLanguage()
            currentLanguage = detectedLanguage
            isSystemLanguageDetected = true
            
            saveLanguagePreference(detectedLanguage)
            markLanguageSetupCompleted()
            
            Logger.info("🆕 LocalizationManager: First launch - detected and set language: \(detectedLanguage.displayName)")
        } else {
            // La app ya se ha abierto antes - cargar preferencia guardada
            if let savedLanguageCode = userDefaults.string(forKey: userDefaultsKey),
               let savedLanguage = SupportedLanguage(rawValue: savedLanguageCode) {
                currentLanguage = savedLanguage
                Logger.info("📱 LocalizationManager: Loaded saved language: \(savedLanguage.displayName)")
            } else {
                // Fallback en caso de que no haya preferencia guardada
                currentLanguage = detectSystemLanguage()
                saveLanguagePreference(currentLanguage)
                Logger.info("🔄 LocalizationManager: No saved preference found, using detected language: \(currentLanguage.displayName)")
            }
        }
    }
    
    func saveLanguagePreference(_ language: SupportedLanguage) {
        userDefaults.set(language.rawValue, forKey: userDefaultsKey)
        Logger.debug("💾 LocalizationManager: Saved language preference: \(language.displayName)")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

// MARK: - Environment Key for SwiftUI
struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue: LocalizationManager = MainActor.assumeIsolated {
        LocalizationManager()
    }
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Extension
extension View {
    func localizationManager(_ manager: LocalizationManager) -> some View {
        environment(\.localizationManager, manager)
    }
}

// MARK: - Debug Extensions
#if DEBUG
extension LocalizationManager {
    static func preview() -> LocalizationManager {
        return MainActor.assumeIsolated {
            LocalizationManager()
        }
    }
    
    func debugLanguageInfo() {
        Logger.debug("🔍 LocalizationManager Debug Info:")
        Logger.debug("  Current Language: \(currentLanguage.displayName)")
        Logger.debug("  System Language Detected: \(isSystemLanguageDetected)")
        Logger.debug("  Is First Setup: \(isFirstLanguageSetup)")
        Logger.debug("  Preferred Languages: \(Locale.preferredLanguages)")
        Logger.debug("  Current Locale: \(getCurrentLocale().identifier)")
    }
}
#endif
