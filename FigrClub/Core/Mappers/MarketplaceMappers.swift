//
//  MarketplaceMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Marketplace Mappers
struct MarketplaceMappers {
    
    static func toMarketplaceResponse(from dto: MarketplaceItemResponseDTO) -> MarketplaceItemResponse {
        return GenericResponseMapper.mapResponse(from: dto, dataMapper: mapMarketplaceItem)
    }
    
    static func toMarketplaceItemListResponse(from dto: MarketplaceItemListResponseDTO) -> MarketplaceItemListResponse {
        return GenericResponseMapper.mapResponse(from: dto) { listData in
            PaginatedData<MarketplaceItem>(
                content: listData.content.map(mapMarketplaceItem),
                totalElements: listData.totalElements,
                totalPages: listData.totalPages,
                currentPage: listData.currentPage,
                size: listData.size
            )
        }
    }
    
    private static func mapMarketplaceItem(_ dto: MarketplaceItemDataDTO) -> MarketplaceItem {
        return MarketplaceItem(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            price: dto.price,
            currency: dto.currency,
            sellerId: dto.sellerId,
            categoryId: dto.categoryId,
            condition: EnumMapper.mapToEnum(rawValue: dto.condition, defaultValue: ItemCondition.good),
            isAvailable: dto.isAvailable,
            createdAt: DateMapper.dateFromString(dto.createdAt) ?? Date(),
            updatedAt: DateMapper.dateFromString(dto.updatedAt) ?? Date(),
            location: dto.location,
            imageUrls: dto.imageUrls
        )
    }
}
