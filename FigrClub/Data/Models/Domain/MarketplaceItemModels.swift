//
//  MarketplaceItemModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation

// MARK: - Marketplace Models
struct MarketplaceItem: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let currency: String
    let condition: ItemCondition
    let category: Category
    let images: [String]
    let seller: User
    let status: ItemStatus
    let createdAt: String
    let updatedAt: String?
    let stockQuantity: Int
    let viewsCount: Int
    let favoritesCount: Int
    let location: ItemLocation?
    
    // User interaction flags
    let isFavoritedByCurrentUser: Bool?
    let canEdit: Bool?
    let canDelete: Bool?
    let canMakeOffer: Bool?
    let canAskQuestion: Bool?
}

enum ItemCondition: String, Codable, CaseIterable {
    case new = "NEW"
    case likeNew = "LIKE_NEW"
    case good = "GOOD"
    case fair = "FAIR"
    case poor = "POOR"
}

enum ItemStatus: String, Codable, CaseIterable {
    case available = "AVAILABLE"
    case sold = "SOLD"
    case reserved = "RESERVED"
    case inactive = "INACTIVE"
}

struct ItemLocation: Codable {
    let country: String
    let city: String
    let region: String?
}
