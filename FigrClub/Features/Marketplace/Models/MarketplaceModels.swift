//
//  MarketplaceModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

struct MarketplaceItem {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let currency: String
    let sellerId: Int
    let categoryId: Int
    let condition: ItemCondition
    let isAvailable: Bool
    let createdAt: Date
    let updatedAt: Date
    let location: String?
    let imageUrls: [String]
}

typealias MarketplaceItemResponse = ApiResponse<MarketplaceItem>
typealias MarketplaceItemListResponse = ApiResponse<PaginatedData<MarketplaceItem>>

enum ItemCondition: String {
    case new = "NEW"
    case likeNew = "LIKE_NEW"
    case good = "GOOD"
    case fair = "FAIR"
    case poor = "POOR"
}
