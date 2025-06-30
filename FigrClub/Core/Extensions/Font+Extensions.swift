//
//  Font+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

extension Font {
    static let figrLargeTitle = Font.custom("SF Pro Display", size: 34).weight(.bold)
    static let figrTitle = Font.custom("SF Pro Display", size: 28).weight(.bold)
    static let figrTitle2 = Font.custom("SF Pro Display", size: 22).weight(.bold)
    static let figrTitle3 = Font.custom("SF Pro Display", size: 20).weight(.semibold)
    static let figrHeadline = Font.custom("SF Pro Text", size: 17).weight(.semibold)
    static let figrBody = Font.custom("SF Pro Text", size: 17).weight(.regular)
    static let figrCallout = Font.custom("SF Pro Text", size: 16).weight(.regular)
    static let figrSubheadline = Font.custom("SF Pro Text", size: 15).weight(.regular)
    static let figrFootnote = Font.custom("SF Pro Text", size: 13).weight(.regular)
    static let figrCaption = Font.custom("SF Pro Text", size: 12).weight(.regular)
    static let figrCaption2 = Font.custom("SF Pro Text", size: 11).weight(.regular)
}
