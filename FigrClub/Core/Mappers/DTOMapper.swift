//
//  DTOMapper.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

private extension Date {
    init(fromTimestamp timestamp: Double) {
        self.init(timeIntervalSince1970: timestamp / 1000.0)
    }
    
    var toTimestamp: Double {
        return timeIntervalSince1970 * 1000.0
    }
}

// MARK: - Base Mapper Protocol
protocol DTOMapper {
    associatedtype DTO: BaseDTO
    associatedtype DomainModel
    
    static func toDomainModel(from dto: DTO) -> DomainModel
    static func toDTO(from domainModel: DomainModel) -> DTO
}

// MARK: - Base API Response Mapper
struct ApiResponseMapper {
    static func toDomainModel<DTOData, DomainData>(
        from dto: ApiResponseDTO<DTOData>,
        dataMapper: (DTOData) -> DomainData
    ) -> ApiResponse<DomainData> {
        return ApiResponse(
            message: dto.message,
            data: dataMapper(dto.data),
            timestamp: Date(fromTimestamp: dto.timestamp),
            currency: dto.currency,
            locale: dto.locale,
            status: dto.status
        )
    }
}

// MARK: - Auth Mappers (With Generic)
struct AuthMappers {
    
    static func toAuthResponse(from dto: AuthResponseDTO) -> AuthResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { authDataDTO in
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
        return ApiResponseMapper.toDomainModel(from: dto) { registerDataDTO in
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

// MARK: - User Mappers (With Generic)
struct UserMappers {
    
    static func toUserResponse(from dto: UserResponseDTO) -> UserResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { userResponseDTO in
            UserResponseData(
                roleInfo: RoleInfo(
                    isAdmin: userResponseDTO.roleInfo.isAdmin,
                    roleModifiable: userResponseDTO.roleInfo.roleModifiable,
                    roleModificationReason: userResponseDTO.roleInfo.roleModificationReason,
                    roleName: userResponseDTO.roleInfo.roleName
                ),
                user: mapUserFromDTO(userResponseDTO.user)
            )
        }
    }
    
    private static func mapUserFromDTO(_ dto: UserDTO) -> User {
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
            imageCapabilities: dto.imageCapabilities.map { mapImageCapabilitiesFromDTO($0) },
            maxProfileImageSizeMB: dto.maxProfileImageSizeMB,
            maxCoverImageSizeMB: dto.maxCoverImageSizeMB
        )
    }
    
    private static func mapImageCapabilitiesFromDTO(_ dto: ImageCapabilitiesDTO) -> ImageCapabilities {
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

// MARK: - Post Mappers (With Generic)
struct PostMappers {
    
    static func toPostResponse(from dto: PostResponseDTO) -> PostResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { postDataDTO in
            mapPostFromDTO(postDataDTO)
        }
    }
    
    static func toPostListResponse(from dto: PostListResponseDTO) -> PostListResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { postListDataDTO in
            PostListData(
                content: postListDataDTO.content.map { mapPostFromDTO($0) },
                totalElements: postListDataDTO.totalElements,
                totalPages: postListDataDTO.totalPages,
                currentPage: postListDataDTO.currentPage,
                size: postListDataDTO.size
            )
        }
    }
    
    private static func mapPostFromDTO(_ dto: PostDataDTO) -> Post {
        return Post(
            id: dto.id,
            title: dto.title,
            content: dto.content,
            authorId: dto.authorId,
            categoryId: dto.categoryId,
            visibility: PostVisibility(rawValue: dto.visibility) ?? .publicPost,
            publishedAt: dto.publishedAt.flatMap { DateFormatter.iso8601.date(from: $0) },
            createdAt: DateFormatter.iso8601.date(from: dto.createdAt) ?? Date(),
            updatedAt: DateFormatter.iso8601.date(from: dto.updatedAt) ?? Date(),
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
        return ApiResponseMapper.toDomainModel(from: dto) { locationDataDTO in
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
                accuracy: LocationAccuracy(rawValue: locationDataDTO.accuracy) ?? .unknown,
                detected: locationDataDTO.detected
            )
        }
    }
}

// MARK: - Notification Mappers
struct NotificationResponseMapper {
    static func toDomainModel(from dto: NotificationResponseDTO) -> NotificationResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { notificationDataDTO in
            NotificationMapper.toDomainModel(from: notificationDataDTO)
        }
    }
}

struct NotificationListResponseMapper {
    static func toDomainModel(from dto: NotificationListResponseDTO) -> NotificationListResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { notificationListDataDTO in
            NotificationListDataMapper.toDomainModel(from: notificationListDataDTO)
        }
    }
}

struct NotificationListDataMapper: DTOMapper {
    typealias DTO = NotificationListDataDTO
    typealias DomainModel = NotificationListData
    
    static func toDomainModel(from dto: NotificationListDataDTO) -> NotificationListData {
        return NotificationListData(
            content: dto.content.map { NotificationMapper.toDomainModel(from: $0) },
            totalElements: dto.totalElements,
            totalPages: dto.totalPages,
            currentPage: dto.currentPage,
            size: dto.size
        )
    }
    
    static func toDTO(from domainModel: NotificationListData) -> NotificationListDataDTO {
        return NotificationListDataDTO(
            content: domainModel.content.map { NotificationMapper.toDTO(from: $0) },
            totalElements: domainModel.totalElements,
            totalPages: domainModel.totalPages,
            currentPage: domainModel.currentPage,
            size: domainModel.size
        )
    }
}

struct NotificationMapper: DTOMapper {
    typealias DTO = NotificationDataDTO
    typealias DomainModel = NotificationData
    
    static func toDomainModel(from dto: NotificationDataDTO) -> NotificationData {
        return NotificationData(
            id: dto.id,
            userId: dto.userId,
            title: dto.title,
            message: dto.message,
            type: NotificationType(rawValue: dto.type) ?? .system,
            isRead: dto.isRead,
            createdAt: DateFormatter.iso8601.date(from: dto.createdAt) ?? Date(),
            actionUrl: dto.actionUrl,
            metadata: dto.metadata
        )
    }
    
    static func toDTO(from domainModel: NotificationData) -> NotificationDataDTO {
        return NotificationDataDTO(
            id: domainModel.id,
            userId: domainModel.userId,
            title: domainModel.title,
            message: domainModel.message,
            type: domainModel.type.rawValue,
            isRead: domainModel.isRead,
            createdAt: DateFormatter.iso8601.string(from: domainModel.createdAt),
            actionUrl: domainModel.actionUrl,
            metadata: domainModel.metadata
        )
    }
}

// MARK: - Marketplace Mappers
struct MarketplaceItemResponseMapper {
    static func toDomainModel(from dto: MarketplaceItemResponseDTO) -> MarketplaceItemResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { itemDataDTO in
            MarketplaceItemMapper.toDomainModel(from: itemDataDTO)
        }
    }
}

struct MarketplaceItemListResponseMapper {
    static func toDomainModel(from dto: MarketplaceItemListResponseDTO) -> MarketplaceItemListResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { itemListDataDTO in
            MarketplaceItemListDataMapper.toDomainModel(from: itemListDataDTO)
        }
    }
}

struct MarketplaceItemListDataMapper: DTOMapper {
    typealias DTO = MarketplaceItemListDataDTO
    typealias DomainModel = MarketplaceItemListData
    
    static func toDomainModel(from dto: MarketplaceItemListDataDTO) -> MarketplaceItemListData {
        return MarketplaceItemListData(
            content: dto.content.map { MarketplaceItemMapper.toDomainModel(from: $0) },
            totalElements: dto.totalElements,
            totalPages: dto.totalPages,
            currentPage: dto.currentPage,
            size: dto.size
        )
    }
    
    static func toDTO(from domainModel: MarketplaceItemListData) -> MarketplaceItemListDataDTO {
        return MarketplaceItemListDataDTO(
            content: domainModel.content.map { MarketplaceItemMapper.toDTO(from: $0) },
            totalElements: domainModel.totalElements,
            totalPages: domainModel.totalPages,
            currentPage: domainModel.currentPage,
            size: domainModel.size
        )
    }
}

struct MarketplaceItemMapper: DTOMapper {
    typealias DTO = MarketplaceItemDataDTO
    typealias DomainModel = MarketplaceItem
    
    static func toDomainModel(from dto: MarketplaceItemDataDTO) -> MarketplaceItem {
        return MarketplaceItem(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            price: dto.price,
            currency: dto.currency,
            sellerId: dto.sellerId,
            categoryId: dto.categoryId,
            condition: ItemCondition(rawValue: dto.condition) ?? .good,
            isAvailable: dto.isAvailable,
            createdAt: DateFormatter.iso8601.date(from: dto.createdAt) ?? Date(),
            updatedAt: DateFormatter.iso8601.date(from: dto.updatedAt) ?? Date(),
            location: dto.location,
            imageUrls: dto.imageUrls
        )
    }
    
    static func toDTO(from domainModel: MarketplaceItem) -> MarketplaceItemDataDTO {
        return MarketplaceItemDataDTO(
            id: domainModel.id,
            title: domainModel.title,
            description: domainModel.description,
            price: domainModel.price,
            currency: domainModel.currency,
            sellerId: domainModel.sellerId,
            categoryId: domainModel.categoryId,
            condition: domainModel.condition.rawValue,
            isAvailable: domainModel.isAvailable,
            createdAt: DateFormatter.iso8601.string(from: domainModel.createdAt),
            updatedAt: DateFormatter.iso8601.string(from: domainModel.updatedAt),
            location: domainModel.location,
            imageUrls: domainModel.imageUrls
        )
    }
}

// MARK: - Domain Response Types (Using Generic ApiResponse)
typealias AuthResponse = ApiResponse<AuthData>
typealias RegisterResponse = ApiResponse<RegisterData>
typealias UserResponse = ApiResponse<UserResponseData>
typealias PostResponse = ApiResponse<Post>
typealias PostListResponse = ApiResponse<PostListData>
typealias LocationResponse = ApiResponse<Location>
typealias NotificationResponse = ApiResponse<NotificationData>
typealias NotificationListResponse = ApiResponse<NotificationListData>
typealias MarketplaceItemResponse = ApiResponse<MarketplaceItem>
typealias MarketplaceItemListResponse = ApiResponse<MarketplaceItemListData>

struct PostListData {
    let content: [Post]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
}

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

struct NotificationListData {
    let content: [NotificationData]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
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

struct MarketplaceItemListData {
    let content: [MarketplaceItem]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
}
