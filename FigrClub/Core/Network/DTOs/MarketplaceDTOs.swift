//
//  MarketplaceDTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Marketplace DTOs
struct MarketplaceItemDataDTO: BaseDTO {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let currency: String
    let sellerId: Int
    let categoryId: Int
    let condition: String
    let isAvailable: Bool
    let createdAt: String
    let updatedAt: String
    let location: String?
    let imageUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, price, currency
        case sellerId = "seller_id"
        case categoryId = "category_id"
        case condition
        case isAvailable = "is_available"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case location
        case imageUrls = "image_urls"
    }
}

typealias MarketplaceItemResponseDTO = ApiResponseDTO<MarketplaceItemDataDTO>

struct MarketplaceItemListDataDTO: BaseDTO {
    let content: [MarketplaceItemDataDTO]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case content
        case totalElements = "total_elements"
        case totalPages = "total_pages"
        case currentPage = "current_page"
        case size
    }
}

typealias MarketplaceItemListResponseDTO = ApiResponseDTO<MarketplaceItemListDataDTO>
