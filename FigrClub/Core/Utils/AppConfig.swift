//
//  AppConfig.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

// MARK: - App Configuration
enum AppConfig {
    enum API {
        static let baseURL = "http://localhost:9092/figrclub/api/v1"
        static let timeout: TimeInterval = 30
    }
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let animationDuration: Double = 0.3
    }
}
