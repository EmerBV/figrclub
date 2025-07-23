//
//  View+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

extension View {
    /// Aplica el tema global a la vista (implementación auto-suficiente)
    func themed() -> some View {
        self.modifier(ThemedView())
    }
    
    /// Aplica una fuente temática
    func themedFont(_ fontType: ThemedFontType) -> some View {
        self.modifier(ThemedFontModifier(fontType: fontType))
    }
    
    /// Aplica un color de fondo temático
    func themedBackground() -> some View {
        self.modifier(ThemedBackgroundModifier())
    }
    
    /// Aplica un color de tarjeta temático
    func themedCard() -> some View {
        self.modifier(ThemedCardModifier())
    }
    
    /// Aplica colores de texto temáticos
    func themedTextColor(_ level: TextColorLevel = .primary) -> some View {
        self.modifier(ThemedTextColorModifier(level: level))
    }
}

// MARK: - Themed View Modifier (implementación auto-suficiente)
struct ThemedView: ViewModifier {
    @StateObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .environmentObject(themeManager)
            .environment(\.themeManager, themeManager)
            .environment(\.colorScheme, themeManager.colorScheme)
            .accentColor(themeManager.accentColor)
            .preferredColorScheme(
                themeManager.themeMode == .system ? nil :
                    (themeManager.themeMode == .dark ? .dark : .light)
            )
    }
}

// MARK: - Themed Background Modifier

struct ThemedBackgroundModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.currentBackgroundColor)
    }
}

// MARK: - Themed Card Modifier

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(
                themeManager.currentCardColor
                    .cornerRadius(AppTheme.CornerRadius.card)
                    .shadow(
                        color: AppTheme.Shadow.cardShadowColor,
                        radius: AppTheme.Shadow.cardShadow.radius,
                        x: AppTheme.Shadow.cardShadow.x,
                        y: AppTheme.Shadow.cardShadow.y
                    )
            )
    }
}

// MARK: - Text Color Level

enum TextColorLevel {
    case primary
    case secondary
    case tertiary
    case accent
}

// MARK: - Themed Text Color Modifier

struct ThemedTextColorModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let level: TextColorLevel
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(colorForLevel(level))
    }
    
    private func colorForLevel(_ level: TextColorLevel) -> Color {
        switch level {
        case .primary:
            return themeManager.currentTextColor
        case .secondary:
            return themeManager.currentSecondaryTextColor
        case .tertiary:
            return themeManager.colorScheme == .dark ?
            Color.figrDarkTextTertiary : Color.figrTextTertiary
        case .accent:
            return themeManager.accentColor
        }
    }
}

// MARK: - Card Extensions

extension View {
    /// Aplica estilo de tarjeta FigrClub
    func figrCard() -> some View {
        self.modifier(FigrCardModifier())
    }
    
    /// Aplica padding de tarjeta FigrClub
    func figrCardPadding(_ padding: CGFloat = AppTheme.Spacing.cardPadding) -> some View {
        self.padding(padding)
    }
    
    /// Aplica sombra de tarjeta FigrClub
    func figrCardShadow() -> some View {
        self.shadow(
            color: AppTheme.Shadow.cardShadowColor,
            radius: AppTheme.Shadow.cardShadow.radius,
            x: AppTheme.Shadow.cardShadow.x,
            y: AppTheme.Shadow.cardShadow.y
        )
    }
}

struct FigrCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.currentCardColor)
            .cornerRadius(AppTheme.CornerRadius.card)
            .figrCardShadow()
    }
}

// MARK: - Button Extensions

extension View {
    /// Aplica estilo de botón primario temático
    func figrPrimaryButton() -> some View {
        self.modifier(FigrPrimaryButtonModifier())
    }
    
    /// Aplica estilo de botón secundario temático
    func figrSecondaryButton() -> some View {
        self.modifier(FigrSecondaryButtonModifier())
    }
    
    /// Aplica estilo de botón outline temático
    func figrOutlineButton() -> some View {
        self.modifier(FigrOutlineButtonModifier())
    }
}

// MARK: - Custom Themed Text Field Modifier

struct ThemedTextFieldModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let isValid: Bool
    
    init(isValid: Bool = true) {
        self.isValid = isValid
    }
    
    func body(content: Content) -> some View {
        content
            .themedFont(.bodyMedium)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.buttonPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.input)
                    .fill(themeManager.currentCardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.input)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var borderColor: Color {
        if !isValid {
            return .figrError
        }
        return themeManager.colorScheme == .dark ?
        Color.figrDarkBorder : Color.figrBorder
    }
    
    private var borderWidth: CGFloat {
        !isValid ? 1.5 : 0.5
    }
}

struct FigrPrimaryButtonModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(buttonColor)
            )
            .shadow(
                color: AppTheme.Shadow.buttonShadowColor,
                radius: AppTheme.Shadow.buttonShadow.radius,
                x: AppTheme.Shadow.buttonShadow.x,
                y: AppTheme.Shadow.buttonShadow.y
            )
            .disabled(!isEnabled || isLoading)
    }
    
    private var buttonColor: Color {
        if !isEnabled || isLoading {
            return themeManager.currentSecondaryTextColor.opacity(0.6)
        }
        return themeManager.accentColor
    }
}

struct FigrSecondaryButtonModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .themedFont(.buttonMedium)
            .foregroundColor(themeManager.accentColor)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(themeManager.currentCardColor)
            .cornerRadius(AppTheme.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(themeManager.accentColor, lineWidth: 1)
            )
    }
}

struct FigrOutlineButtonModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .themedFont(.buttonMedium)
            .themedTextColor(.primary)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(Color.clear)
            .cornerRadius(AppTheme.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(themeManager.currentSecondaryTextColor.opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - Loading Extensions

extension View {
    /// Aplica overlay de loading temático
    func figrLoading(_ isLoading: Bool) -> some View {
        self.modifier(FigrLoadingModifier(isLoading: isLoading))
    }
    
    /// Aplica shimmer effect temático
    func figrShimmer(_ isActive: Bool = true) -> some View {
        self.modifier(FigrShimmerModifier(isActive: isActive))
    }
}

struct FigrLoadingModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isLoading {
                        ZStack {
                            themeManager.currentBackgroundColor.opacity(0.8)
                            
                            VStack(spacing: AppTheme.Spacing.medium) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                                    .scaleEffect(1.2)
                                
                                Text("Cargando...")
                                    .themedFont(.bodyMedium)
                                    .themedTextColor(.secondary)
                            }
                        }
                        .cornerRadius(AppTheme.CornerRadius.card)
                    }
                }
            )
    }
}

struct FigrShimmerModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let isActive: Bool
    @State private var startPoint = UnitPoint.leading
    @State private var endPoint = UnitPoint.trailing
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isActive {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        themeManager.accentColor.opacity(0.3),
                                        Color.clear
                                    ]),
                                    startPoint: startPoint,
                                    endPoint: endPoint
                                )
                            )
                            .onAppear {
                                withAnimation(AppTheme.Animation.shimmer) {
                                    startPoint = UnitPoint.trailing
                                    endPoint = UnitPoint.leading
                                }
                            }
                    }
                }
            )
    }
}

// MARK: - Navigation Extensions

extension View {
    /// Aplica estilo de navegación temático
    func figrNavigation() -> some View {
        self.modifier(FigrNavigationModifier())
    }
    
    /// Aplica barra de navegación transparente temática
    func figrTransparentNavigation() -> some View {
        self.modifier(FigrTransparentNavigationModifier())
    }
}

struct FigrNavigationModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(themeManager.currentCardColor)
                appearance.titleTextAttributes = [
                    .foregroundColor: UIColor(themeManager.currentTextColor)
                ]
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: UIColor(themeManager.currentTextColor)
                ]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

struct FigrTransparentNavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

// MARK: - Accessibility Extensions

extension View {
    /// Aplica configuraciones de accesibilidad temática
    func figrAccessibility() -> some View {
        self.modifier(FigrAccessibilityModifier())
    }
}

struct FigrAccessibilityModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        //.environment(\.sizeCategory, themeManager.preferredFontSize.sizeCategory)
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

// MARK: - Debug Extensions

#if DEBUG
extension View {
    /// Imprime valores para debugging
    func debugPrint(_ value: Any) -> some View {
        print("🐛 Debug: \(value)")
        return self
    }
    
    /// Aplica fondo de debug
    func debugBackground(_ color: Color = .red) -> some View {
        self.background(color.opacity(0.3))
    }
    
    /// Aplica borde de debug
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: width)
        )
    }
    
    /// Muestra información de debug temática
    func debugThemeInfo() -> some View {
        self.modifier(DebugThemeInfoModifier())
    }
}

struct DebugThemeInfoModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎨 Theme Debug")
                        .font(.caption.bold())
                    Text("Mode: \(themeManager.themeMode.displayName)")
                    Text("Scheme: \(themeManager.colorScheme == .dark ? "Dark" : "Light")")
                    Text("Font: \(themeManager.preferredFontSize.displayName)")
                    Text("Contrast: \(themeManager.isHighContrastEnabled ? "On" : "Off")")
                }
                    .font(.caption2)
                    .padding(8)
                    .background(.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8),
                alignment: .topTrailing
            )
    }
}

struct DebugInfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🏗️ Debug Info")
                .font(.caption.bold())
            Text("Version: \(AppConfig.shared.appVersion)")
            Text("Build: \(AppConfig.shared.buildNumber)")
            Text("API: \(AppConfig.shared.apiBaseURL)")
            Text("Theme: \(themeManager.themeMode.displayName)")
            Text("Colors: \(themeManager.colorScheme == .dark ? "Dark" : "Light")")
        }
        .font(.caption2)
        .padding(8)
        .background(.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}
#endif

// MARK: - Animation Extensions

extension View {
    /// Aplica animación de aparición temática
    func figrAppearAnimation() -> some View {
        self.modifier(FigrAppearAnimationModifier())
    }
    
    /// Aplica animación de tap temática
    func figrTapAnimation() -> some View {
        self.modifier(FigrTapAnimationModifier())
    }
}

struct FigrAppearAnimationModifier: ViewModifier {
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(AppTheme.Animation.medium) {
                    appeared = true
                }
            }
    }
}

struct FigrTapAnimationModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .onTapGesture {
                withAnimation(AppTheme.Animation.buttonTap) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AppTheme.Animation.buttonTap) {
                        isPressed = false
                    }
                }
            }
    }
}

// MARK: - Layout Extensions

extension View {
    /// Aplica padding estándar de pantalla
    func figrScreenPadding() -> some View {
        self.padding(.horizontal, AppTheme.Spacing.screenPadding)
    }
    
    /// Aplica padding de sección
    func figrSectionPadding() -> some View {
        self.padding(.vertical, AppTheme.Spacing.sectionSpacing)
    }
    
    /// Aplica espaciado estándar
    func figrSpacing(_ size: AppTheme.Spacing.Size = .medium) -> some View {
        self.padding(size.value)
    }
}

// MARK: - Spacing Size Extension

extension AppTheme.Spacing {
    enum Size {
        case tiny, small, medium, large, xlarge, xxlarge
        
        var value: CGFloat {
            switch self {
            case .tiny: return AppTheme.Spacing.tiny
            case .small: return AppTheme.Spacing.small
            case .medium: return AppTheme.Spacing.medium
            case .large: return AppTheme.Spacing.large
            case .xlarge: return AppTheme.Spacing.xlarge
            case .xxlarge: return AppTheme.Spacing.xxlarge
            }
        }
    }
}

// MARK: - Conditional Extensions

extension View {
    /// Aplica modificador condicionalmente
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Aplica modificador condicionalmente con else
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Safe Area Extensions

extension View {
    /// Ignora safe area con color de fondo temático
    func figrIgnoreSafeArea(_ regions: SafeAreaRegions = .all) -> some View {
        self.modifier(FigrIgnoreSafeAreaModifier(regions: regions))
    }
}

struct FigrIgnoreSafeAreaModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let regions: SafeAreaRegions
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.currentBackgroundColor.ignoresSafeArea(regions))
    }
}

// MARK: - Keyboard Extensions

extension View {
    /// Maneja el teclado automáticamente
    func figrKeyboardHandling() -> some View {
        self.modifier(FigrKeyboardModifier())
    }
}

struct FigrKeyboardModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    withAnimation(AppTheme.Animation.medium) {
                        keyboardHeight = keyboardFrame.cgRectValue.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(AppTheme.Animation.medium) {
                    keyboardHeight = 0
                }
            }
    }
}

// MARK: - Performance Extensions

extension View {
    /// Optimiza el renderizado para listas grandes
    func figrListOptimization() -> some View {
        self.modifier(FigrListOptimizationModifier())
    }
}

struct FigrListOptimizationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .drawingGroup() // Agrupa el dibujo para mejor performance
    }
}

// MARK: - Error Handling Extensions

extension View {
    /// Maneja errores con UI temática
    func figrErrorHandling<ErrorType: Error>(
        error: Binding<ErrorType?>,
        onRetry: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(FigrErrorHandlingModifier(error: error, onRetry: onRetry))
    }
}

struct FigrErrorHandlingModifier<ErrorType: Error>: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var error: ErrorType?
    let onRetry: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("Reintentar", action: onRetry)
                Button("Cerrar") { error = nil }
            } message: {
                Text(error?.localizedDescription ?? "Ha ocurrido un error inesperado")
            }
    }
}
