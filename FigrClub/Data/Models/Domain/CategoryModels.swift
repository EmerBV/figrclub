//
//  CategoryModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation

// MARK: - Category Models
struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let parentId: Int?
    let imageUrl: String?
    let isActive: Bool
}
