//
//  Colors.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Brand Colors
    /*
    static let figrPrimary = Color(red: 0.2, green: 0.3, blue: 0.5) // Azul profundo profesional #334D80
    static let figrSecondary = Color(red: 0.85, green: 0.65, blue: 0.2) // Dorado premium #D9A533
    static let figrAccent = Color(red: 0.85, green: 0.65, blue: 0.2) // Mismo que secondary para coherencia
     */
    
    static let figrPrimary = Color(red: 0.157, green: 0.196, blue: 0.341) // #283257
    static let figrSecondary = Color(red: 1.0, green: 0.839, blue: 0.0) // #FFD600
    static let figrAccent = Color(red: 1.0, green: 0.839, blue: 0.0)
    
    static let figrBlueAccent = Color(red: 0.247, green: 0.604, blue: 0.957) // #3F9AF4
    static let figrRedAccent = Color(red: 0.863, green: 0.035, blue: 0.078) // #DC0914 //#E40714
    static let figrDarkDanger = Color(red: 0.69, green: 0.035, blue: 0.078) // #B00914
    static let figrOrangeAccent = Color(red: 0.863, green: 0.035, blue: 0.078) // #EC4809
    
    
    // MARK: - Background Colors (Light Mode)
    static let figrBackground = Color(red: 0.97, green: 0.97, blue: 0.98) // Gris muy claro #F7F7FA // #6c6464
    static let figrSurface = Color(red: 0.95, green: 0.95, blue: 0.97) // Gris superficie #F2F2F7
    static let figrCard = Color.white // Blanco puro para tarjetas
    
    // MARK: - Dark Mode Backgrounds
    static let figrDarkBackground = Color(red: 0.08, green: 0.08, blue: 0.1) // #141419 // #645c5c
    static let figrDarkSurface = Color(red: 0.10, green: 0.10, blue: 0.12) // #1A1A1F
    static let figrDarkCard = Color(red: 0.12, green: 0.12, blue: 0.15) // #1F1F26
    
    // MARK: - Text Colors
    static let figrTextPrimary = Color(red: 0.15, green: 0.15, blue: 0.15) // Gris oscuro #262626
    static let figrTextSecondary = Color(red: 0.45, green: 0.45, blue: 0.45) // Gris medio #737373
    static let figrTextTertiary = Color(red: 0.65, green: 0.65, blue: 0.65) // Gris claro #A6A6A6
    
    // MARK: - Dark Mode Text Colors
    static let figrDarkTextPrimary = Color(red: 0.95, green: 0.95, blue: 0.95) // Blanco suave
    static let figrDarkTextSecondary = Color(red: 0.75, green: 0.75, blue: 0.75) // Gris claro
    static let figrDarkTextTertiary = Color(red: 0.55, green: 0.55, blue: 0.55) // Gris medio
    
    // MARK: - Border Colors
    static let figrDarkBorder = Color(red: 0.90, green: 0.90, blue: 0.90) //
    static let figrBorder = Color(red: 0.90, green: 0.90, blue: 0.90) // Borde sutil
    static let figrDivider = Color(red: 0.85, green: 0.85, blue: 0.85) // Divisor más visible
    
    // MARK: - Status Colors
    static let figrSuccess = Color(red: 0.2, green: 0.7, blue: 0.4) // Verde confiable #33B366
    static let figrWarning = Color(red: 0.9, green: 0.6, blue: 0.1) // Ámbar #E69A1A
    static let figrError = Color(red: 0.8, green: 0.2, blue: 0.2) // Rojo controlado #CC3333
    static let figrInfo = Color(red: 0.2, green: 0.4, blue: 0.8) // Azul información
    
    // MARK: - Social Colors
    static let figrLike = Color(red: 0.9, green: 0.3, blue: 0.4) // Rojo like suave
    static let figrComment = Color(red: 0.3, green: 0.5, blue: 0.8) // Azul comentario
    static let figrShare = Color(red: 0.2, green: 0.7, blue: 0.4) // Verde compartir
    static let figrBookmark = Color(red: 0.85, green: 0.65, blue: 0.2) // Dorado bookmark
    
    // MARK: - Figure Rarity Colors
    static let figrFigureCommon = Color(red: 0.55, green: 0.55, blue: 0.55) // Gris común
    static let figrFigureUncommon = Color(red: 0.3, green: 0.6, blue: 0.3) // Verde poco común
    static let figrFigureRare = Color(red: 0.2, green: 0.4, blue: 0.8) // Azul raro
    static let figrFigureEpic = Color(red: 0.6, green: 0.2, blue: 0.8) // Púrpura épico
    static let figrFigureLegendary = Color(red: 0.9, green: 0.5, blue: 0.1) // Naranja legendario
    static let figrFigureMythic = Color(red: 0.85, green: 0.65, blue: 0.2) // Dorado mítico
    
    // MARK: - Gradient Colors
    static let figrGradientBlueStart = Color.figrBlueAccent.opacity(0.6)
    static let figrGradientBlueEnd = Color.figrPrimary.opacity(0.9)
    static let figrGradientStart = Color.figrPrimary.opacity(0.8)
    static let figrGradientEnd = Color.figrSecondary.opacity(0.6)
    
    // MARK: - Market Colors
    static let figrPriceUp = Color(red: 0.2, green: 0.7, blue: 0.4) // Verde subida
    static let figrPriceDown = Color(red: 0.8, green: 0.2, blue: 0.2) // Rojo bajada
    static let figrPriceNeutral = Color(red: 0.5, green: 0.5, blue: 0.5) // Gris neutral
    
    // MARK: - Interactive Colors
    static let figrButtonPrimary = Color.figrPrimary
    static let figrButtonSecondary = Color.figrSecondary
    static let figrButtonDisabled = Color(red: 0.85, green: 0.85, blue: 0.85)
    static let figrButtonText = Color.white
    static let figrButtonSecondaryText = Color.figrTextPrimary
    
    static let figrButtonBlueText = Color.figrBlueAccent
}

// MARK: - Adaptive Colors (responden al modo oscuro)
extension Color {
    static var adaptiveBackground: Color {
        Color(.systemBackground)
    }
    
    /// Color de tarjeta adaptativo de la marca FigrClub
    /// Modo claro: Blanco puro, Modo oscuro: Gris oscuro específico de la marca
    static var adaptiveCard: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0) // #1F1F26 - Color de marca en oscuro
            default:
                return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // Blanco puro en claro
            }
        })
    }
    
    /// Color de texto primario adaptativo de la marca FigrClub
    /// Modo claro: Gris oscuro específico, Modo oscuro: Gris claro específico de la marca
    static var adaptiveTextPrimary: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // Gris claro de marca en oscuro
            default:
                return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0) // Gris oscuro de marca en claro
            }
        })
    }
}

// MARK: - Color Utilities
extension Color {
    /// Creates a color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Returns hex string representation of the color
    var hexString: String {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else { return "#000000" }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}

// MARK: - Color Accessibility
extension Color {
    /// Returns true if the color provides sufficient contrast with white text
    var needsLightText: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate relative luminance
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance < 0.5
    }
}
