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
    
    // MARK: - Computed Properties
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: currencyLocale)
        
        return formatter.string(from: NSNumber(value: price)) ?? "\(price) \(currency)"
    }
    
    var sellerName: String {
        return seller.fullName
    }
    
    var formattedCondition: String {
        switch condition {
        case .new:
            return "Nuevo"
        case .likeNew:
            return "Como nuevo"
        case .good:
            return "Bueno"
        case .fair:
            return "Regular"
        case .poor:
            return "Malo"
        }
    }
    
    var statusDescription: String {
        switch status {
        case .active:
            return "Activo"
        case .available:
            return "Disponible"
        case .sold:
            return "Vendido"
        case .reserved:
            return "Reservado"
        case .inactive:
            return "Inactivo"
        case .deleted:
            return "Eliminado"
        }
    }
    
    var mainImageUrl: String? {
        return images.first
    }
    
    var isAvailable: Bool {
        return status == .available && stockQuantity > 0
    }
    
    var shortDescription: String {
        if description.count > 100 {
            return String(description.prefix(97)) + "..."
        }
        return description
    }
    
    private var currencyLocale: String {
        switch currency {
        case "EUR":
            return "es_ES"
        case "USD":
            return "en_US"
        case "GBP":
            return "en_GB"
        default:
            return "es_ES"
        }
    }
}

enum ItemCondition: String, Codable, CaseIterable {
    case new = "NEW"
    case likeNew = "LIKE_NEW"
    case good = "GOOD"
    case fair = "FAIR"
    case poor = "POOR"
    
    var displayName: String {
        switch self {
        case .new: return "Nuevo"
        case .likeNew: return "Como nuevo"
        case .good: return "Bueno"
        case .fair: return "Regular"
        case .poor: return "Malo"
        }
    }
    
    var color: String {
        switch self {
        case .new: return "green"
        case .likeNew: return "blue"
        case .good: return "orange"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
}

enum ItemStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case available = "AVAILABLE"
    case sold = "SOLD"
    case reserved = "RESERVED"
    case inactive = "INACTIVE"
    case deleted = "DELETED"
    
    var displayName: String {
        switch self {
        case .active: return "Activo"
        case .available: return "Disponible"
        case .sold: return "Vendido"
        case .reserved: return "Reservado"
        case .inactive: return "Inactivo"
        case .deleted: return "Eliminado"
        }
    }
}

struct ItemLocation: Codable {
    let country: String
    let city: String
    let region: String?
    
    var fullLocation: String {
        var components = [city, country]
        if let region = region {
            components.insert(region, at: 1)
        }
        return components.joined(separator: ", ")
    }
}

// MARK: - Marketplace Search Filters
struct MarketplaceSearchFilters: Codable {
    let categoryId: Int?
    let minPrice: Double?
    let maxPrice: Double?
    let condition: ItemCondition?
    let location: String?
    let sortBy: MarketplaceSortOption?
    let sortDirection: SortDirection?
}

enum MarketplaceSortOption: String, Codable, CaseIterable {
    case price = "price"
    case createdAt = "createdAt"
    case title = "title"
    case popularity = "popularity"
    case relevance = "relevance"
    
    var displayName: String {
        switch self {
        case .price: return "Precio"
        case .createdAt: return "Fecha"
        case .title: return "Título"
        case .popularity: return "Popularidad"
        case .relevance: return "Relevancia"
        }
    }
}

enum SortDirection: String, Codable, CaseIterable {
    case asc = "ASC"
    case desc = "DESC"
    
    var displayName: String {
        switch self {
        case .asc: return "Ascendente"
        case .desc: return "Descendente"
        }
    }
}

// MARK: - Marketplace Item Extensions
/*
 extension MarketplaceItem {
 
 static func mock() -> MarketplaceItem {
 return MarketplaceItem(
 id: 1,
 title: "Figura de Goku Super Saiyan",
 description: "Figura coleccionable de Dragon Ball Z en perfecto estado. Incluye base y efectos especiales.",
 price: 49.99,
 currency: "EUR",
 condition: .likeNew,
 category: Category.mock(),
 images: [
 "https://example.com/image1.jpg",
 "https://example.com/image2.jpg"
 ],
 seller: User.mock(),
 status: .available,
 createdAt: "2024-01-15T10:30:00Z",
 updatedAt: nil,
 stockQuantity: 1,
 viewsCount: 125,
 favoritesCount: 8,
 location: ItemLocation(country: "España", city: "Madrid", region: "Madrid"),
 isFavoritedByCurrentUser: false,
 canEdit: false,
 canDelete: false,
 canMakeOffer: true,
 canAskQuestion: true
 )
 }
 }
 */
