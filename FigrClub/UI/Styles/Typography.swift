//
//  Typography.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import SwiftUI

// MARK: - Typography System
extension Font {
    
    // MARK: - Display Fonts (Para títulos principales y marketing)
    static let figrDisplayLarge = Font.custom("SF Pro Display", size: 32)
        .weight(.heavy)
    static let figrDisplayMedium = Font.custom("SF Pro Display", size: 28)
        .weight(.bold)
    static let figrDisplaySmall = Font.custom("SF Pro Display", size: 24)
        .weight(.semibold)
    
    // MARK: - Headline Fonts (Para títulos de secciones)
    static let figrHeadlineLarge = Font.custom("SF Pro Display", size: 22)
        .weight(.bold)
    static let figrHeadlineMedium = Font.custom("SF Pro Display", size: 20)
        .weight(.semibold)
    static let figrHeadlineSmall = Font.custom("SF Pro Display", size: 18)
        .weight(.medium)
    
    // MARK: - Title Fonts (Para títulos de tarjetas y elementos)
    static let figrTitleLarge = Font.custom("SF Pro Text", size: 18)
        .weight(.semibold)
    static let figrTitleMedium = Font.custom("SF Pro Text", size: 16)
        .weight(.medium)
    static let figrTitleSmall = Font.custom("SF Pro Text", size: 14)
        .weight(.medium)
    
    // MARK: - Body Text (Para contenido principal)
    static let figrBodyLarge = Font.custom("SF Pro Text", size: 17)
        .weight(.regular)
    static let figrBodyMedium = Font.custom("SF Pro Text", size: 16)
        .weight(.regular)
    static let figrBodySmall = Font.custom("SF Pro Text", size: 15)
        .weight(.regular)
    
    // MARK: - Label Fonts (Para etiquetas y metadatos)
    static let figrLabelLarge = Font.custom("SF Pro Text", size: 15)
        .weight(.medium)
    static let figrLabelMedium = Font.custom("SF Pro Text", size: 13)
        .weight(.medium)
    static let figrLabelSmall = Font.custom("SF Pro Text", size: 11)
        .weight(.semibold)
    
    // MARK: - Caption Fonts (Para texto auxiliar)
    static let figrCaptionLarge = Font.custom("SF Pro Text", size: 13)
        .weight(.regular)
    static let figrCaptionMedium = Font.custom("SF Pro Text", size: 12)
        .weight(.regular)
    static let figrCaptionSmall = Font.custom("SF Pro Text", size: 11)
        .weight(.regular)
    
    // MARK: - Special Purpose Fonts
    
    // Para precios y valores numéricos importantes
    static let figrPriceLarge = Font.custom("SF Mono", size: 20)
        .weight(.bold)
    static let figrPriceMedium = Font.custom("SF Mono", size: 18)
        .weight(.semibold)
    static let figrPriceSmall = Font.custom("SF Mono", size: 16)
        .weight(.medium)
    static let figrPriceTiny = Font.custom("SF Mono", size: 14)
        .weight(.regular)
    
    // Para botones
    static let figrButtonLarge = Font.custom("SF Pro Text", size: 18)
        .weight(.semibold)
    static let figrButtonMedium = Font.custom("SF Pro Text", size: 16)
        .weight(.medium)
    static let figrButtonSmall = Font.custom("SF Pro Text", size: 14)
        .weight(.medium)
    
    // Para navegación
    static let figrNavTitle = Font.custom("SF Pro Display", size: 20)
        .weight(.semibold)
    static let figrTabBar = Font.custom("SF Pro Text", size: 12)
        .weight(.medium)
    
    // Para rareza de figuras (con estilo especial)
    static let figrRarityLarge = Font.custom("SF Pro Display", size: 16)
        .weight(.bold)
    static let figrRaritySmall = Font.custom("SF Pro Text", size: 12)
        .weight(.bold)
}

// MARK: - Text Styles for Common Use Cases
struct FigrTextStyle {
    
    // MARK: - Product Card Styles
    static let productTitle: some View = {
        AnyView(
            Text("Sample")
                .font(.figrTitleMedium)
                .foregroundColor(.figrTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        )
    }()
    
    static let productPrice: some View = {
        AnyView(
            Text("$99.99")
                .font(.figrPriceMedium)
                .foregroundColor(.figrPrimary)
                .bold()
        )
    }()
    
    static let productDescription: some View = {
        AnyView(
            Text("Sample description")
                .font(.figrBodySmall)
                .foregroundColor(.figrTextSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        )
    }()
    
    // MARK: - User Profile Styles
    static let username: some View = {
        AnyView(
            Text("@username")
                .font(.figrTitleMedium)
                .foregroundColor(.figrTextPrimary)
                .bold()
        )
    }()
    
    static let userBio: some View = {
        AnyView(
            Text("Bio text")
                .font(.figrBodyMedium)
                .foregroundColor(.figrTextSecondary)
                .multilineTextAlignment(.leading)
        )
    }()
    
    // MARK: - Navigation Styles
    static let navigationTitle: some View = {
        AnyView(
            Text("Title")
                .font(.figrNavTitle)
                .foregroundColor(.figrTextPrimary)
        )
    }()
    
    // MARK: - Status Styles
    static let successText: some View = {
        AnyView(
            Text("Success")
                .font(.figrLabelMedium)
                .foregroundColor(.figrSuccess)
        )
    }()
    
    static let errorText: some View = {
        AnyView(
            Text("Error")
                .font(.figrLabelMedium)
                .foregroundColor(.figrError)
        )
    }()
    
    static let warningText: some View = {
        AnyView(
            Text("Warning")
                .font(.figrLabelMedium)
                .foregroundColor(.figrWarning)
        )
    }()
}

// MARK: - Dynamic Type Support
extension Font {
    static func figrDynamic(_ textStyle: Font.TextStyle, design: Font.Design = .default) -> Font {
        return Font.system(textStyle, design: design)
    }
    
    // Método para crear fuentes que se adaptan al tamaño dinámico del usuario
    static func figrScaled(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        return Font.system(size: size, weight: weight, design: design)
    }
}

// MARK: - Text Modifiers
extension Text {
    // Modificador para aplicar el estilo de precio
    func priceStyle() -> some View {
        self
            .font(.figrPriceMedium)
            .foregroundColor(.figrPrimary)
            .bold()
    }
    
    // Modificador para rareza de figuras
    func rarityStyle(rarity: FigureRarity) -> some View {
        self
            .font(.figrRaritySmall)
            .foregroundColor(rarity.color)
            .textCase(.uppercase)
            .bold()
    }
    
    // Modificador para títulos de sección
    func sectionTitle() -> some View {
        self
            .font(.figrHeadlineSmall)
            .foregroundColor(.figrTextPrimary)
            .bold()
    }
    
    // Modificador para subtítulos
    func subtitle() -> some View {
        self
            .font(.figrBodyMedium)
            .foregroundColor(.figrTextSecondary)
    }
    
    // Modificador para metadatos (fecha, categoría, etc.)
    func metadata() -> some View {
        self
            .font(.figrCaptionMedium)
            .foregroundColor(.figrTextTertiary)
    }
}

// MARK: - Figure Rarity Enum (para el sistema de rareza)
enum FigureRarity: String, CaseIterable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case mythic = "mythic"
    
    var displayName: String {
        switch self {
        case .common: return "Común"
        case .uncommon: return "Poco Común"
        case .rare: return "Raro"
        case .epic: return "Épico"
        case .legendary: return "Legendario"
        case .mythic: return "Mítico"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .figrFigureCommon
        case .uncommon: return .figrFigureUncommon
        case .rare: return .figrFigureRare
        case .epic: return .figrFigureEpic
        case .legendary: return .figrFigureLegendary
        case .mythic: return .figrFigureMythic
        }
    }
}

// MARK: - Line Height and Spacing
extension Text {
    func lineSpacing(_ spacing: CGFloat) -> Text {
        return self.lineSpacing(spacing)
    }
    
    func customLineHeight(_ lineHeight: CGFloat, fontSize: CGFloat) -> some View {
        self.lineSpacing(lineHeight - fontSize)
    }
}
