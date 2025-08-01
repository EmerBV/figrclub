//
//  AppTheme.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import SwiftUI

// MARK: - App Theme Configuration
struct AppTheme {
    
    // MARK: - Spacing System
    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 48
        
        // Specific use cases
        static let screenPadding: CGFloat = 20
    }
    
    enum LayoutConstants {
        static let segmentControlHeight: CGFloat = 44
        static let badgeSize: CGFloat = 20
        static let itemSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 8
        static let avatarSize: CGFloat = 56
    }
    
    // MARK: - Corner Radius System
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        
        // Specific components
        static let card: CGFloat = 12
        static let button: CGFloat = 10
        static let input: CGFloat = 8
        static let image: CGFloat = 8
        static let modal: CGFloat = 16
    }
    
    // MARK: - Shadow System
    struct Shadow {
        static let cardShadow: (radius: CGFloat, x: CGFloat, y: CGFloat) = (8, 0, 4)
        static let buttonShadow: (radius: CGFloat, x: CGFloat, y: CGFloat) = (4, 0, 2)
        static let modalShadow: (radius: CGFloat, x: CGFloat, y: CGFloat) = (16, 0, 8)
        
        static let cardShadowColor = Color.black.opacity(0.1)
        static let buttonShadowColor = Color.black.opacity(0.15)
        static let modalShadowColor = Color.black.opacity(0.2)
    }
    
    // MARK: - Animation System
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        // Specific animations
        static let buttonTap = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let modalPresent = SwiftUI.Animation.easeOut(duration: 0.4)
        static let shimmer = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }
    
    // MARK: - Icon Sizes
    struct IconSize {
        static let tiny: CGFloat = 12
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 80
        
        // Specific use cases
        static let tabBar: CGFloat = 22
        static let navigation: CGFloat = 20
        static let button: CGFloat = 16
        static let list: CGFloat = 18
    }
    
    // MARK: - Card Styles
    static var cardStyle: some ViewModifier {
        CardModifier()
    }
    
    static var elevatedCardStyle: some ViewModifier {
        ElevatedCardModifier()
    }
    
    static var productCardStyle: some ViewModifier {
        ProductCardModifier()
    }
}

// MARK: - Card Modifiers
private struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(colorScheme == .dark ? Color.figrDarkCard : Color.figrCard)
                    .shadow(
                        color: AppTheme.Shadow.cardShadowColor,
                        radius: AppTheme.Shadow.cardShadow.radius,
                        x: AppTheme.Shadow.cardShadow.x,
                        y: AppTheme.Shadow.cardShadow.y
                    )
            )
    }
}

private struct ElevatedCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(colorScheme == .dark ? Color.figrDarkCard : Color.figrCard)
                    .shadow(
                        color: AppTheme.Shadow.modalShadowColor,
                        radius: AppTheme.Shadow.modalShadow.radius,
                        x: AppTheme.Shadow.modalShadow.x,
                        y: AppTheme.Shadow.modalShadow.y
                    )
            )
    }
}

private struct ProductCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(colorScheme == .dark ? Color.figrDarkCard : Color.figrCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                            .stroke(Color.figrBorder.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(
                        color: AppTheme.Shadow.cardShadowColor,
                        radius: AppTheme.Shadow.cardShadow.radius,
                        x: AppTheme.Shadow.cardShadow.x,
                        y: AppTheme.Shadow.cardShadow.y
                    )
            )
    }
}

// MARK: - Button Styles
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == OutlineButtonStyle {
    static var outline: OutlineButtonStyle { OutlineButtonStyle() }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.figrButtonMedium)
            .foregroundColor(.figrButtonText)
            .padding(.horizontal, AppTheme.Spacing.xLarge)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(Color.figrPrimary)
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            )
            .shadow(
                color: AppTheme.Shadow.buttonShadowColor,
                radius: configuration.isPressed ? 2 : AppTheme.Shadow.buttonShadow.radius,
                x: AppTheme.Shadow.buttonShadow.x,
                y: configuration.isPressed ? 1 : AppTheme.Shadow.buttonShadow.y
            )
            .animation(AppTheme.Animation.buttonTap, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.figrButtonMedium)
            .foregroundColor(.figrTextPrimary)
            .padding(.horizontal, AppTheme.Spacing.xLarge)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(Color.figrSecondary.opacity(0.15))
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            )
            .animation(AppTheme.Animation.buttonTap, value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.figrButtonMedium)
            .foregroundColor(.figrPrimary)
            .padding(.horizontal, AppTheme.Spacing.xLarge)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(Color.figrPrimary, lineWidth: 1.5)
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            )
            .animation(AppTheme.Animation.buttonTap, value: configuration.isPressed)
    }
}

struct FigrTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.figrBodyMedium)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.input)
                    .fill(Color.figrCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.input)
                            .stroke(Color.figrBorder, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Layout Helpers
struct FigrVStack<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = AppTheme.Spacing.large, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content
        }
    }
}

struct FigrHStack<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = AppTheme.Spacing.large, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            content
        }
    }
}

// MARK: - Navigation Helpers
struct FigrNavigationStack<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo temático automático
                themeManager.currentBackgroundColor
                    .ignoresSafeArea()
                
                content
            }
        }
    }
}

struct FigrNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo temático automático
                themeManager.currentBackgroundColor
                    .ignoresSafeArea()
                
                content
            }
        }
        .navigationViewStyle(.stack) // Fuerza stack style en iPad
    }
}

// MARK: - Screen Container con Navigation
struct FigrScreenContainer<Content: View>: View {
    let content: Content
    let useNavigationStack: Bool
    
    init(useNavigationStack: Bool = true, @ViewBuilder content: () -> Content) {
        self.useNavigationStack = useNavigationStack
        self.content = content()
    }
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if useNavigationStack {
                NavigationStack {
                    containerContent
                }
            } else {
                NavigationView {
                    containerContent
                }
                .navigationViewStyle(.stack)
            }
        }
    }
    
    private var containerContent: some View {
        ZStack {
            // Fondo temático
            themeManager.currentBackgroundColor
                .ignoresSafeArea()
            
            // Contenido con padding estándar
            content
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
        }
    }
}

// MARK: - ScrollView Helpers
struct FigrScrollView<Content: View>: View {
    let axes: Axis.Set
    let content: Content
    
    init(_ axes: Axis.Set = .vertical, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: false) {
            content
        }
    }
}

// MARK: - ScrollView con RefreshAction
struct FigrRefreshableScrollView<Content: View>: View {
    let axes: Axis.Set
    let refreshAction: () async -> Void
    let content: Content
    
    init(
        _ axes: Axis.Set = .vertical,
        refreshAction: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.refreshAction = refreshAction
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: false) {
            content
        }
        .refreshable {
            await refreshAction()
        }
    }
}

// MARK: - ScrollView Shortcuts Específicos
struct FigrVerticalScrollView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
        }
    }
}

struct FigrHorizontalScrollView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            content
        }
    }
}

// MARK: - Loading States
struct FigrShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black,
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(70))
                    .offset(x: isAnimating ? 200 : -200)
            )
            .onAppear {
                withAnimation(AppTheme.Animation.shimmer) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Screen Container Modifier
struct ScreenContainerModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppTheme.Spacing.screenPadding)
            .background(
                (colorScheme == .dark ? Color.figrDarkBackground : Color.figrBackground)
                    .ignoresSafeArea()
            )
    }
}

// MARK: - Specific Component Themes
struct FigrPriceTag: View {
    let price: String
    let originalPrice: String?
    let size: PriceSize
    
    enum PriceSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .figrPriceSmall
            case .medium: return .figrPriceMedium
            case .large: return .figrPriceLarge
            }
        }
        
        var originalFont: Font {
            switch self {
            case .small: return .figrCaptionSmall
            case .medium: return .figrCaptionMedium
            case .large: return .figrBodySmall
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.small) {
            Text(price)
                .font(size.font)
                .foregroundColor(.figrPrimary)
                .bold()
            
            if let originalPrice = originalPrice {
                Text(originalPrice)
                    .font(size.originalFont)
                    .foregroundColor(.figrTextTertiary)
                    .strikethrough()
            }
        }
    }
}

struct FigrRarityBadge: View {
    let rarity: FigureRarity
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium
        
        var font: Font {
            switch self {
            case .small: return .figrRaritySmall
            case .medium: return .figrRarityLarge
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            }
        }
    }
    
    var body: some View {
        Text(rarity.displayName)
            .font(size.font)
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(rarity.color)
            )
    }
}

// MARK: - Theme Environment
struct ThemeEnvironment {
    static let shared = ThemeEnvironment()
    
    // Aquí podrías agregar configuraciones dinámicas del tema
    // como preferencias del usuario, modo oscuro automático, etc.
}
