//
//  Font+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import SwiftUI

// MARK: - Font Extensions
extension Font {
    // Títulos
    static let figrLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let figrTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let figrTitle2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let figrTitle3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Texto
    static let figrHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let figrBody = Font.system(size: 17, weight: .regular, design: .default)
    static let figrCallout = Font.system(size: 16, weight: .regular, design: .default)
    static let figrSubheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let figrFootnote = Font.system(size: 13, weight: .regular, design: .default)
    static let figrCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let figrCaption2 = Font.system(size: 11, weight: .regular, design: .default)
}
