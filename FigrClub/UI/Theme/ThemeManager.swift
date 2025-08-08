//
//  ThemeManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import SwiftUI
import Combine

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var colorScheme: ColorScheme = .light
    @Published var accentColor: Color = .figrSecondary
    @Published var isHighContrastEnabled: Bool = false
    @Published var preferredFontSize: FontSizePreference = .medium
    
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Initializer (sin singleton)
    nonisolated init() {
        Task { @MainActor in
            self.loadUserPreferences()
            self.setupSystemColorSchemeObserver()
        }
    }
    
    // MARK: - Font Size Preferences
    enum FontSizePreference: String, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extraLarge"
        
        var displayName: String {
            switch self {
            case .small: return "Pequeño"
            case .medium: return "Mediano"
            case .large: return "Grande"
            case .extraLarge: return "Extra Grande"
            }
        }
        
        var scaleFactor: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.1
            case .extraLarge: return 1.2
            }
        }
    }
    
    // MARK: - Theme Mode
    enum ThemeMode: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light: return "Claro"
            case .dark: return "Oscuro"
            case .system: return "Sistema"
            }
        }
        
        var icon: String {
            switch self {
            case .light: return "sun.max"
            case .dark: return "moon"
            case .system: return "gear"
            }
        }
    }
    
    @Published var themeMode: ThemeMode = .system {
        didSet {
            updateColorScheme()
            saveUserPreferences()
        }
    }
    
    // MARK: - Computed Properties
    var currentBackgroundColor: Color {
        colorScheme == .dark ? .figrDarkBackground : .figrBackground
    }
    
    var currentCardColor: Color {
        colorScheme == .dark ? .figrDarkCard : .figrCard
    }
    
    var currentTextColor: Color {
        colorScheme == .dark ? .figrDarkTextPrimary : .figrTextPrimary
    }
    
    var currentSecondaryTextColor: Color {
        colorScheme == .dark ? .figrDarkTextSecondary : .figrTextSecondary
    }
    
    var currentBorderColor: Color {
        colorScheme == .dark ? .figrDarkBorder.opacity(0.2) : .figrBorder
    }
    
    // MARK: - Public Methods
    func toggleColorScheme() {
        switch themeMode {
        case .light:
            themeMode = .dark
        case .dark:
            themeMode = .system
        case .system:
            themeMode = .light
        }
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
    }
    
    func setFontSizePreference(_ preference: FontSizePreference) {
        preferredFontSize = preference
        saveUserPreferences()
    }
    
    func enableHighContrast(_ enabled: Bool) {
        isHighContrastEnabled = enabled
        saveUserPreferences()
    }
    
    func setAccentColor(_ color: Color) {
        accentColor = color
        saveUserPreferences()
    }
    
    // MARK: - Private Methods
    private func updateColorScheme() {
        switch themeMode {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = getSystemColorScheme()
        }
    }
    
    private func getSystemColorScheme() -> ColorScheme {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
        return .light
    }
    
    private func setupSystemColorSchemeObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.themeMode == .system {
                self?.updateColorScheme()
            }
        }
    }
    
    // MARK: - UserDefaults
    private func loadUserPreferences() {
        let themeString = UserDefaults.standard.string(forKey: "ThemeMode") ?? "system"
        themeMode = ThemeMode(rawValue: themeString) ?? .system
        
        let fontSizeString = UserDefaults.standard.string(forKey: "FontSizePreference") ?? "medium"
        preferredFontSize = FontSizePreference(rawValue: fontSizeString) ?? .medium
        
        isHighContrastEnabled = UserDefaults.standard.bool(forKey: "HighContrastEnabled")
        
        updateColorScheme()
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(themeMode.rawValue, forKey: "ThemeMode")
        UserDefaults.standard.set(preferredFontSize.rawValue, forKey: "FontSizePreference")
        UserDefaults.standard.set(isHighContrastEnabled, forKey: "HighContrastEnabled")
    }
}

// MARK: - Theme Environment Key
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - Themed Font Types
enum ThemedFontType {
    case displayLarge, displayMedium, displaySmall
    case headlineLarge, headlineMedium, headlineSmall
    case titleLarge, titleMedium, titleSmall
    case bodyLarge, bodyMedium, bodySmall, bodyXSmall
    case buttonLarge, buttonMedium, buttonSmall
    case priceLarge, priceMedium, priceSmall
}

// MARK: - Themed Font Modifier
struct ThemedFontModifier: ViewModifier {
    let fontType: ThemedFontType
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .font(getFontForType())
    }
    
    private func getFontForType() -> Font {
        let scaleFactor = themeManager.accessibilityTextScaleFactor
        
        switch fontType {
        case .displayLarge:
            return .scaledForTheme(baseSize: 32, weight: .heavy, scaleFactor: scaleFactor)
        case .displayMedium:
            return .scaledForTheme(baseSize: 28, weight: .bold, scaleFactor: scaleFactor)
        case .displaySmall:
            return .scaledForTheme(baseSize: 24, weight: .semibold, scaleFactor: scaleFactor)
        case .headlineLarge:
            return .scaledForTheme(baseSize: 22, weight: .bold, scaleFactor: scaleFactor)
        case .headlineMedium:
            return .scaledForTheme(baseSize: 20, weight: .semibold, scaleFactor: scaleFactor)
        case .headlineSmall:
            return .scaledForTheme(baseSize: 18, weight: .medium, scaleFactor: scaleFactor)
        case .titleLarge:
            return .scaledForTheme(baseSize: 18, weight: .semibold, scaleFactor: scaleFactor)
        case .titleMedium:
            return .scaledForTheme(baseSize: 16, weight: .medium, scaleFactor: scaleFactor)
        case .titleSmall:
            return .scaledForTheme(baseSize: 14, weight: .medium, scaleFactor: scaleFactor)
        case .bodyLarge:
            return .scaledForTheme(baseSize: 17, weight: .regular, scaleFactor: scaleFactor)
        case .bodyMedium:
            return .scaledForTheme(baseSize: 16, weight: .regular, scaleFactor: scaleFactor)
        case .bodySmall:
            return .scaledForTheme(baseSize: 15, weight: .regular, scaleFactor: scaleFactor)
        case .bodyXSmall:
            return .scaledForTheme(baseSize: 12, weight: .regular, scaleFactor: scaleFactor)
        case .buttonLarge:
            return .scaledForTheme(baseSize: 18, weight: .semibold, scaleFactor: scaleFactor)
        case .buttonMedium:
            return .scaledForTheme(baseSize: 16, weight: .medium, scaleFactor: scaleFactor)
        case .buttonSmall:
            return .scaledForTheme(baseSize: 14, weight: .medium, scaleFactor: scaleFactor)
        case .priceLarge:
            return Font.custom("SF Mono", size: 20 * scaleFactor).weight(.bold)
        case .priceMedium:
            return Font.custom("SF Mono", size: 18 * scaleFactor).weight(.semibold)
        case .priceSmall:
            return Font.custom("SF Mono", size: 16 * scaleFactor).weight(.medium)
        }
    }
}

// MARK: - Font Size Category Extension
extension ThemeManager.FontSizePreference {
    var sizeCategory: DynamicTypeSize {
        switch self {
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .extraLarge:
            return .xLarge
        }
    }
}

// MARK: - Accessibility Support
extension ThemeManager {
    var accessibilityTextScaleFactor: CGFloat {
        let dynamicTypeSize = UIApplication.shared.preferredContentSizeCategory
        let baseScale = preferredFontSize.scaleFactor
        
        switch dynamicTypeSize {
        case .extraSmall, .small, .medium:
            return baseScale * 0.9
        case .large:
            return baseScale
        case .extraLarge, .extraExtraLarge:
            return baseScale * 1.1
        case .extraExtraExtraLarge:
            return baseScale * 1.2
        case .accessibilityMedium:
            return baseScale * 1.3
        case .accessibilityLarge:
            return baseScale * 1.4
        case .accessibilityExtraLarge:
            return baseScale * 1.5
        case .accessibilityExtraExtraLarge:
            return baseScale * 1.6
        case .accessibilityExtraExtraExtraLarge:
            return baseScale * 1.7
        default:
            return baseScale
        }
    }
    
    var shouldUseHighContrast: Bool {
        isHighContrastEnabled ||
        UIAccessibility.isDarkerSystemColorsEnabled ||
        UIAccessibility.isInvertColorsEnabled
    }
}

// MARK: - High Contrast Colors
extension Color {
    static var figrHighContrastPrimary: Color {
        Color(red: 0.0, green: 0.2, blue: 0.8) // Azul más intenso
    }
    
    static var figrHighContrastTextPrimary: Color {
        Color(red: 0.0, green: 0.0, blue: 0.0) // Negro puro
    }
    
    static var figrHighContrastBackground: Color {
        Color(red: 1.0, green: 1.0, blue: 1.0) // Blanco puro
    }
}

// MARK: - Font Extensions with Theme Support
extension Font {
    static func scaledForTheme(baseSize: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, scaleFactor: CGFloat) -> Font {
        return .system(size: baseSize * scaleFactor, weight: weight, design: design)
    }
}

// MARK: - Theme-aware Font Helper
@MainActor
struct ThemedFont {
    static func displayLarge(themeManager: ThemeManager) -> Font {
        .scaledForTheme(baseSize: 32, weight: .heavy, scaleFactor: themeManager.accessibilityTextScaleFactor)
    }
    
    static func displayMedium(themeManager: ThemeManager) -> Font {
        .scaledForTheme(baseSize: 28, weight: .bold, scaleFactor: themeManager.accessibilityTextScaleFactor)
    }
    
    static func bodyMedium(themeManager: ThemeManager) -> Font {
        .scaledForTheme(baseSize: 16, weight: .regular, scaleFactor: themeManager.accessibilityTextScaleFactor)
    }
    
    static func titleMedium(themeManager: ThemeManager) -> Font {
        .scaledForTheme(baseSize: 16, weight: .medium, scaleFactor: themeManager.accessibilityTextScaleFactor)
    }
    
    static func buttonMedium(themeManager: ThemeManager) -> Font {
        .scaledForTheme(baseSize: 16, weight: .medium, scaleFactor: themeManager.accessibilityTextScaleFactor)
    }
}
