//
//  DTOMapper.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - Domain Response Types (Using Generic ApiResponse)
typealias AuthResponse = ApiResponse<AuthData>
typealias RegisterResponse = ApiResponse<RegisterData>
typealias UserResponse = ApiResponse<UserResponseData>
typealias LegalDocumentResponse = ApiResponse<LegalDocumentData>
typealias PostResponse = ApiResponse<Post>
typealias PostListResponse = ApiResponse<PaginatedData<Post>>
typealias LocationResponse = ApiResponse<Location>
typealias NotificationResponse = ApiResponse<NotificationData>
typealias NotificationListResponse = ApiResponse<PaginatedData<NotificationData>>
typealias MarketplaceItemResponse = ApiResponse<MarketplaceItem>
typealias MarketplaceItemListResponse = ApiResponse<PaginatedData<MarketplaceItem>>


