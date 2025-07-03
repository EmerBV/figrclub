//
//  Color+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

extension Color {    
    // Converts Color to UIColor
    var uiColor: UIColor {
        UIColor(self)
    }
}

extension Color {
    // Primary Colors
    static let figrPrimary = Color("FigrPrimary", bundle: nil)
    static let figrSecondary = Color("FigrSecondary", bundle: nil)
    static let figrAccent = Color("FigrAccent", bundle: nil)
    
    // Background Colors
    static let figrBackground = Color("FigrBackground", bundle: nil)
    static let figrSurface = Color("FigrSurface", bundle: nil)
    static let figrCard = Color("FigrCard", bundle: nil)
    
    // Text Colors
    static let figrTextPrimary = Color("FigrTextPrimary", bundle: nil)
    static let figrTextSecondary = Color("FigrTextSecondary", bundle: nil)
    static let figrTextTertiary = Color("FigrTextTertiary", bundle: nil)
    
    // State Colors
    static let figrSuccess = Color("FigrSuccess", bundle: nil)
    static let figrWarning = Color("FigrWarning", bundle: nil)
    static let figrError = Color("FigrError", bundle: nil)
    static let figrInfo = Color("FigrInfo", bundle: nil)
    
    // UI Colors
    static let figrBorder = Color("FigrBorder", bundle: nil)
    static let figrDivider = Color("FigrDivider", bundle: nil)
    static let figrOverlay = Color("FigrOverlay", bundle: nil)
    
    // Fallback colors for missing assets
    init(_ name: String, bundle: Bundle?) {
        if let uiColor = UIColor(named: name, in: bundle, compatibleWith: nil) {
            self.init(uiColor: uiColor)
        } else {
            // Colores por defecto si no se encuentran en Assets
            switch name {
            case "FigrPrimary":
                self.init(hex: "#007AFF")
            case "FigrSecondary":
                self.init(hex: "#5856D6")
            case "FigrAccent":
                self.init(hex: "#FF9500")
            case "FigrBackground":
                self.init(hex: "#F2F2F7")
            case "FigrSurface":
                self.init(hex: "#FFFFFF")
            case "FigrCard":
                self.init(hex: "#FFFFFF")
            case "FigrTextPrimary":
                self.init(hex: "#000000")
            case "FigrTextSecondary":
                self.init(hex: "#8E8E93")
            case "FigrTextTertiary":
                self.init(hex: "#C7C7CC")
            case "FigrSuccess":
                self.init(hex: "#34C759")
            case "FigrWarning":
                self.init(hex: "#FF9500")
            case "FigrError":
                self.init(hex: "#FF3B30")
            case "FigrInfo":
                self.init(hex: "#007AFF")
            case "FigrBorder":
                self.init(hex: "#E5E5E7")
            case "FigrDivider":
                self.init(hex: "#C6C6C8")
            case "FigrOverlay":
                self.init(hex: "#000000", opacity: 0.4)
            default:
                self.init(hex: "#000000")
            }
        }
    }
    
    init(hex: String, opacity: Double = 1.0) {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255 * opacity
        )
    }
}
