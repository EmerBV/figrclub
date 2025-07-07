//
//  Colors.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let figrPrimary = Color.blue
    static let figrSecondary = Color.purple
    static let figrAccent = Color.orange
    
    // MARK: - Background Colors
    static let figrBackground = Color(.systemBackground)
    static let figrSurface = Color(.secondarySystemBackground)
    static let figrCard = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    static let figrTextPrimary = Color(.label)
    static let figrTextSecondary = Color(.secondaryLabel)
    static let figrTextTertiary = Color(.tertiaryLabel)
    
    // MARK: - Border Colors
    static let figrBorder = Color(.separator)
    static let figrDivider = Color(.opaqueSeparator)
    
    // MARK: - Status Colors
    static let figrSuccess = Color.green
    static let figrWarning = Color.orange
    static let figrError = Color.red
    static let figrInfo = Color.blue
    
    // MARK: - Social Colors
    static let figrLike = Color.red
    static let figrComment = Color.blue
    static let figrShare = Color.green
    static let figrBookmark = Color.orange
    
    // MARK: - Gradient Colors
    static let figrGradientStart = Color.blue.opacity(0.8)
    static let figrGradientEnd = Color.purple.opacity(0.6)
    
    // MARK: - Custom Colors
    static let figrFigureRare = Color.gold
    static let figrFigureCommon = Color.gray
    static let figrFigureEpic = Color.purple
    static let figrFigureLegendary = Color.orange
}

// MARK: - Custom Color Extensions
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    
    // Dark mode adaptive colors
    static let adaptiveBackground = Color(.systemBackground)
    static let adaptiveSecondaryBackground = Color(.secondarySystemBackground)
    static let adaptiveTertiaryBackground = Color(.tertiarySystemBackground)
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Returns a lighter version of the color
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: abs(percentage))
    }
    
    /// Returns a darker version of the color
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: -1 * abs(percentage))
    }
    
    private func adjustBrightness(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness += (percentage / 100.0)
            brightness = max(min(brightness, 1.0), 0.0)
            return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
        }
        
        return self
    }
}
