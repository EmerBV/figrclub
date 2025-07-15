//
//  DTOMapper.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - Enhanced Date Extensions
private extension Date {
    init(fromTimestamp timestamp: Double) {
        self.init(timeIntervalSince1970: timestamp / 1000.0)
    }
    
    var toTimestamp: Double {
        return timeIntervalSince1970 * 1000.0
    }
}

// MARK: - Auth Mappers (Simplified with Generic Mapper)
struct AuthMappers {
    
    static func toAuthResponse(from dto: AuthResponseDTO) -> AuthResponse {
        return GenericResponseMapper.mapResponse(from: dto) { authDataDTO in
            AuthData(
                authToken: AuthToken(
                    id: authDataDTO.authToken.id,
                    token: authDataDTO.authToken.token
                ),
                userId: authDataDTO.userId,
                email: authDataDTO.email
            )
        }
    }
    
    static func toRegisterResponse(from dto: RegisterResponseDTO) -> RegisterResponse {
        return GenericResponseMapper.mapResponse(from: dto) { registerDataDTO in
            RegisterData(
                userId: registerDataDTO.userId,
                email: registerDataDTO.email,
                fullName: registerDataDTO.fullName,
                emailVerified: registerDataDTO.emailVerified,
                emailSent: registerDataDTO.emailSent
            )
        }
    }
}

// MARK: - User Mappers (Simplified)
struct UserMappers: Mappable {
    typealias DTO = UserResponseDTO
    typealias DomainModel = UserResponse
    
    static func toDomainModel(from dto: UserResponseDTO) -> UserResponse {
        return GenericResponseMapper.mapResponse(from: dto) { userResponseDTO in
            UserResponseData(
                roleInfo: mapRoleInfo(userResponseDTO.roleInfo),
                user: mapUser(userResponseDTO.user)
            )
        }
    }
    
    static func toDTO(from domainModel: UserResponse) -> UserResponseDTO {
        // Implementation for reverse mapping if needed
        fatalError("Not implemented - typically not needed for API responses")
    }
    
    // MARK: - Convenience Method for AuthService compatibility
    static func toUserResponse(from dto: UserResponseDTO) -> UserResponse {
        return toDomainModel(from: dto)
    }
    
    // MARK: - Private Mapping Methods
    
    private static func mapRoleInfo(_ dto: RoleInfoDTO) -> RoleInfo {
        return RoleInfo(
            isAdmin: dto.isAdmin,
            roleModifiable: dto.roleModifiable,
            roleModificationReason: dto.roleModificationReason,
            roleName: dto.roleName
        )
    }
    
    private static func mapUser(_ dto: UserDTO) -> User {
        return User(
            id: dto.id,
            firstName: dto.firstName,
            lastName: dto.lastName,
            email: dto.email,
            displayName: dto.displayName,
            fullName: dto.fullName,
            birthDate: dto.birthDate,
            city: dto.city,
            country: dto.country,
            phone: dto.phone,
            preferredLanguage: dto.preferredLanguage,
            active: dto.active,
            enabled: dto.enabled,
            accountNonExpired: dto.accountNonExpired,
            accountNonLocked: dto.accountNonLocked,
            credentialsNonExpired: dto.credentialsNonExpired,
            emailVerified: dto.emailVerified,
            emailVerifiedAt: dto.emailVerifiedAt,
            isVerified: dto.isVerified,
            isPrivate: dto.isPrivate,
            isPro: dto.isPro,
            canAccessProFeatures: dto.canAccessProFeatures,
            proSeller: dto.proSeller,
            isActiveSellerProfile: dto.isActiveSellerProfile,
            isSellingActive: dto.isSellingActive,
            individualUser: dto.individualUser,
            admin: dto.admin,
            role: dto.role,
            roleDescription: dto.roleDescription,
            roleId: dto.roleId,
            hasProfileImage: dto.hasProfileImage,
            hasCoverImage: dto.hasCoverImage,
            activeImageCount: dto.activeImageCount,
            followersCount: dto.followersCount,
            followingCount: dto.followingCount,
            postsCount: dto.postsCount,
            purchasesCount: dto.purchasesCount,
            createdAt: dto.createdAt,
            createdBy: dto.createdBy,
            lastActivityAt: dto.lastActivityAt,
            imageCapabilities: dto.imageCapabilities.mapToDomain(using: mapImageCapabilities),
            maxProfileImageSizeMB: dto.maxProfileImageSizeMB,
            maxCoverImageSizeMB: dto.maxCoverImageSizeMB
        )
    }
    
    private static func mapImageCapabilities(_ dto: ImageCapabilitiesDTO) -> ImageCapabilities {
        return ImageCapabilities(
            canUploadProfileImage: dto.canUploadProfileImage,
            canUploadCoverImage: dto.canUploadCoverImage,
            maxProfileImageSize: dto.maxProfileImageSize,
            maxProfileImageSizeMB: dto.maxProfileImageSizeMB,
            maxCoverImageSize: dto.maxCoverImageSize,
            maxCoverImageSizeMB: dto.maxCoverImageSizeMB
        )
    }
}

// MARK: - Post Mappers (Using Generic Paginated Mapper)
struct PostMappers {
    
    static func toPostResponse(from dto: PostResponseDTO) -> PostResponse {
        return GenericResponseMapper.mapResponse(from: dto, dataMapper: mapPost)
    }
    
    static func toPostListResponse(from dto: PostListResponseDTO) -> PostListResponse {
        return GenericResponseMapper.mapResponse(from: dto) { listData in
            PaginatedData<Post>(
                content: listData.content.map(mapPost),
                totalElements: listData.totalElements,
                totalPages: listData.totalPages,
                currentPage: listData.currentPage,
                size: listData.size
            )
        }
    }
    
    private static func mapPost(_ dto: PostDataDTO) -> Post {
        return Post(
            id: dto.id,
            title: dto.title,
            content: dto.content,
            authorId: dto.authorId,
            categoryId: dto.categoryId,
            visibility: EnumMapper.mapToEnum(rawValue: dto.visibility, defaultValue: PostVisibility.publicPost),
            publishedAt: DateMapper.dateFromString(dto.publishedAt),
            createdAt: DateMapper.dateFromString(dto.createdAt) ?? Date(),
            updatedAt: DateMapper.dateFromString(dto.updatedAt) ?? Date(),
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            sharesCount: dto.sharesCount,
            location: dto.location,
            latitude: dto.latitude,
            longitude: dto.longitude,
            hashtags: dto.hashtags,
            mediaUrls: dto.mediaUrls
        )
    }
}

// MARK: - Location Mappers
struct LocationMappers {
    
    static func toLocationResponse(from dto: LocationResponseDTO) -> LocationResponse {
        return GenericResponseMapper.mapResponse(from: dto) { locationDataDTO in
            Location(
                latitude: locationDataDTO.latitude,
                longitude: locationDataDTO.longitude,
                country: locationDataDTO.country,
                city: locationDataDTO.city,
                state: locationDataDTO.state,
                address: locationDataDTO.address,
                postalCode: locationDataDTO.postalCode,
                timezone: locationDataDTO.timezone,
                source: locationDataDTO.source,
                accuracy: EnumMapper.mapToEnum(rawValue: locationDataDTO.accuracy, defaultValue: LocationAccuracy.unknown),
                detected: locationDataDTO.detected
            )
        }
    }
}

// MARK: - Notification Mappers (Using new pattern)
struct NotificationMappers: Mappable {
    typealias DTO = NotificationResponseDTO
    typealias DomainModel = NotificationResponse
    
    static func toDomainModel(from dto: NotificationResponseDTO) -> NotificationResponse {
        return GenericResponseMapper.mapResponse(from: dto, dataMapper: mapNotification)
    }
    
    static func toDTO(from domainModel: NotificationResponse) -> NotificationResponseDTO {
        fatalError("Not implemented - reverse mapping not needed")
    }
    
    static func toNotificationListResponse(from dto: NotificationListResponseDTO) -> NotificationListResponse {
        return GenericResponseMapper.mapResponse(from: dto) { listData in
            PaginatedData<NotificationData>(
                content: listData.content.map(mapNotification),
                totalElements: listData.totalElements,
                totalPages: listData.totalPages,
                currentPage: listData.currentPage,
                size: listData.size
            )
        }
    }
    
    private static func mapNotification(_ dto: NotificationDataDTO) -> NotificationData {
        return NotificationData(
            id: dto.id,
            userId: dto.userId,
            title: dto.title,
            message: dto.message,
            type: EnumMapper.mapToEnum(rawValue: dto.type, defaultValue: NotificationType.system),
            isRead: dto.isRead,
            createdAt: DateMapper.dateFromString(dto.createdAt) ?? Date(),
            actionUrl: dto.actionUrl,
            metadata: dto.metadata
        )
    }
}

// MARK: - Marketplace Mappers (Using new pattern)
struct MarketplaceMappers: Mappable {
    typealias DTO = MarketplaceItemResponseDTO
    typealias DomainModel = MarketplaceItemResponse
    
    static func toDomainModel(from dto: MarketplaceItemResponseDTO) -> MarketplaceItemResponse {
        return GenericResponseMapper.mapResponse(from: dto, dataMapper: mapMarketplaceItem)
    }
    
    static func toDTO(from domainModel: MarketplaceItemResponse) -> MarketplaceItemResponseDTO {
        fatalError("Not implemented - reverse mapping not needed")
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

// MARK: - Domain Response Types (Using Generic ApiResponse)
typealias AuthResponse = ApiResponse<AuthData>
typealias RegisterResponse = ApiResponse<RegisterData>
typealias UserResponse = ApiResponse<UserResponseData>
typealias PostResponse = ApiResponse<Post>
typealias PostListResponse = ApiResponse<PaginatedData<Post>>
typealias LocationResponse = ApiResponse<Location>
typealias NotificationResponse = ApiResponse<NotificationData>
typealias NotificationListResponse = ApiResponse<PaginatedData<NotificationData>>
typealias MarketplaceItemResponse = ApiResponse<MarketplaceItem>
typealias MarketplaceItemListResponse = ApiResponse<PaginatedData<MarketplaceItem>>

// MARK: - Domain Models (Using PaginatedData generic type)

struct Post {
    let id: Int
    let title: String
    let content: String
    let authorId: Int
    let categoryId: Int
    let visibility: PostVisibility
    let publishedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let hashtags: [String]
    let mediaUrls: [String]
}

enum PostVisibility: String {
    case publicPost = "PUBLIC"
    case privatePost = "PRIVATE"
    case friendsPost = "FRIENDS"
}

struct Location {
    let latitude: Double
    let longitude: Double
    let country: String
    let city: String
    let state: String?
    let address: String
    let postalCode: String?
    let timezone: String
    let source: String
    let accuracy: LocationAccuracy
    let detected: Bool
}

enum LocationAccuracy: String {
    case street = "STREET"
    case city = "CITY"
    case region = "REGION"
    case country = "COUNTRY"
    case unknown = "UNKNOWN"
}

struct NotificationData {
    let id: Int
    let userId: Int
    let title: String
    let message: String
    let type: NotificationType
    let isRead: Bool
    let createdAt: Date
    let actionUrl: String?
    let metadata: [String: String]?
}

enum NotificationType: String {
    case like = "LIKE"
    case comment = "COMMENT"
    case follow = "FOLLOW"
    case mention = "MENTION"
    case sale = "SALE"
    case system = "SYSTEM"
}

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

enum ItemCondition: String {
    case new = "NEW"
    case likeNew = "LIKE_NEW"
    case good = "GOOD"
    case fair = "FAIR"
    case poor = "POOR"
}
