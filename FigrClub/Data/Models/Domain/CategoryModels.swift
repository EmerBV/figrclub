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
    let iconName: String?
    let color: String?
    let parentId: Int?
    let isActive: Bool
    let sortOrder: Int
    let createdAt: String
    let updatedAt: String?
    
    var displayIcon: String {
        return iconName ?? "tag"
    }
}

extension Category {
    static func mock() -> Category {
        return Category(
            id: 1,
            name: "Anime",
            description: "Figuras y coleccionables de anime",
            iconName: "star.fill",
            color: "blue",
            parentId: nil,
            isActive: true,
            sortOrder: 1,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: nil
        )
    }
}
