//
//  DTOMapper.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - Base Mapper Protocol
protocol DTOMapper {
    associatedtype DTO: BaseDTO
    associatedtype DomainModel
    
    static func toDomainModel(from dto: DTO) -> DomainModel
    static func toDTO(from domainModel: DomainModel) -> DTO
}

// MARK: - Base API Response Mapper
struct ApiResponseMapper<DTOData: BaseDTO, DomainData> {
    static func toDomainModel(
        from dto: ApiResponseDTO<DTOData>,
        dataMapper: (DTOData) -> DomainData
    ) -> ApiResponse<DomainData> {
        return ApiResponse(
            message: dto.message,
            data: dataMapper(dto.data),
            timestamp: DateFormatter.iso8601.date(from: dto.timestamp) ?? Date(),
            currency: dto.currency,
            locale: dto.locale,
            status: dto.status
        )
    }
    
    static func toDTO(
        from domainModel: ApiResponse<DomainData>,
        dataMapper: (DomainData) -> DTOData
    ) -> ApiResponseDTO<DTOData> {
        return ApiResponseDTO(
            message: domainModel.message,
            data: dataMapper(domainModel.data),
            timestamp: DateFormatter.iso8601.string(from: domainModel.timestamp),
            currency: domainModel.currency,
            locale: domainModel.locale,
            status: domainModel.status
        )
    }
}

// MARK: - Auth Mappers (Simplified with Generic)
struct AuthMapper {
    static func toDomainModel(from dto: AuthResponseDTO) -> AuthResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { authDataDTO in
            AuthDataMapper.toDomainModel(from: authDataDTO)
        }
    }
    
    static func toDTO(from domainModel: AuthResponse) -> AuthResponseDTO {
        return ApiResponseMapper.toDTO(from: domainModel) { authData in
            AuthDataMapper.toDTO(from: authData)
        }
    }
}

struct AuthDataMapper: DTOMapper {
    typealias DTO = AuthDataDTO
    typealias DomainModel = AuthData
    
    static func toDomainModel(from dto: AuthDataDTO) -> AuthData {
        return AuthData(
            authToken: AuthTokenMapper.toDomainModel(from: dto.authToken),
            userId: dto.userId,
            email: dto.email
        )
    }
    
    static func toDTO(from domainModel: AuthData) -> AuthDataDTO {
        return AuthDataDTO(
            authToken: AuthTokenMapper.toDTO(from: domainModel.authToken),
            userId: domainModel.userId,
            email: domainModel.email
        )
    }
}

struct AuthTokenMapper: DTOMapper {
    typealias DTO = AuthTokenDTO
    typealias DomainModel = AuthToken
    
    static func toDomainModel(from dto: AuthTokenDTO) -> AuthToken {
        return AuthToken(
            id: dto.id,
            token: dto.token
        )
    }
    
    static func toDTO(from domainModel: AuthToken) -> AuthTokenDTO {
        return AuthTokenDTO(
            id: domainModel.id,
            token: domainModel.token
        )
    }
}

// MARK: - Register Mapper (Simplified with Generic)
struct RegisterMapper {
    static func toDomainModel(from dto: RegisterResponseDTO) -> RegisterResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { registerDataDTO in
            RegisterDataMapper.toDomainModel(from: registerDataDTO)
        }
    }
    
    static func toDTO(from domainModel: RegisterResponse) -> RegisterResponseDTO {
        return ApiResponseMapper.toDTO(from: domainModel) { registerData in
            RegisterDataMapper.toDTO(from: registerData)
        }
    }
}

struct RegisterDataMapper: DTOMapper {
    typealias DTO = RegisterDataDTO
    typealias DomainModel = RegisterData
    
    static func toDomainModel(from dto: RegisterDataDTO) -> RegisterData {
        return RegisterData(
            userId: dto.userId,
            email: dto.email,
            fullName: dto.fullName,
            emailVerified: dto.emailVerified,
            emailSent: dto.emailSent
        )
    }
    
    static func toDTO(from domainModel: RegisterData) -> RegisterDataDTO {
        return RegisterDataDTO(
            userId: domainModel.userId,
            email: domainModel.email,
            fullName: domainModel.fullName,
            emailVerified: domainModel.emailVerified,
            emailSent: domainModel.emailSent
        )
    }
}

// MARK: - User Mappers (Simplified with Generic)
struct UserResponseMapper {
    static func toDomainModel(from dto: UserResponseDTO) -> UserResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { userResponseDataDTO in
            UserResponseDataMapper.toDomainModel(from: userResponseDataDTO)
        }
    }
    
    static func toDTO(from domainModel: UserResponse) -> UserResponseDTO {
        return ApiResponseMapper.toDTO(from: domainModel) { userResponseData in
            UserResponseDataMapper.toDTO(from: userResponseData)
        }
    }
}

struct UserResponseDataMapper: DTOMapper {
    typealias DTO = UserResponseDataDTO
    typealias DomainModel = UserResponseData
    
    static func toDomainModel(from dto: UserResponseDataDTO) -> UserResponseData {
        return UserResponseData(
            roleInfo: RoleInfoMapper.toDomainModel(from: dto.roleInfo),
            user: UserMapper.toDomainModel(from: dto.user)
        )
    }
    
    static func toDTO(from domainModel: UserResponseData) -> UserResponseDataDTO {
        return UserResponseDataDTO(
            roleInfo: RoleInfoMapper.toDTO(from: domainModel.roleInfo),
            user: UserMapper.toDTO(from: domainModel.user)
        )
    }
}

struct RoleInfoMapper: DTOMapper {
    typealias DTO = RoleInfoDTO
    typealias DomainModel = RoleInfo
    
    static func toDomainModel(from dto: RoleInfoDTO) -> RoleInfo {
        return RoleInfo(
            isAdmin: dto.isAdmin,
            roleModifiable: dto.roleModifiable,
            roleModificationReason: dto.roleModificationReason,
            roleName: dto.roleName
        )
    }
    
    static func toDTO(from domainModel: RoleInfo) -> RoleInfoDTO {
        return RoleInfoDTO(
            isAdmin: domainModel.isAdmin,
            roleModifiable: domainModel.roleModifiable,
            roleModificationReason: domainModel.roleModificationReason,
            roleName: domainModel.roleName
        )
    }
}

struct UserMapper: DTOMapper {
    typealias DTO = UserDTO
    typealias DomainModel = User
    
    static func toDomainModel(from dto: UserDTO) -> User {
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
            imageCapabilities: dto.imageCapabilities.map { ImageCapabilitiesMapper.toDomainModel(from: $0) },
            maxProfileImageSizeMB: dto.maxProfileImageSizeMB,
            maxCoverImageSizeMB: dto.maxCoverImageSizeMB
        )
    }
    
    static func toDTO(from domainModel: User) -> UserDTO {
        return UserDTO(
            id: domainModel.id,
            firstName: domainModel.firstName,
            lastName: domainModel.lastName,
            email: domainModel.email,
            displayName: domainModel.displayName,
            fullName: domainModel.fullName,
            birthDate: domainModel.birthDate,
            city: domainModel.city,
            country: domainModel.country,
            phone: domainModel.phone,
            preferredLanguage: domainModel.preferredLanguage,
            active: domainModel.active,
            enabled: domainModel.enabled,
            accountNonExpired: domainModel.accountNonExpired,
            accountNonLocked: domainModel.accountNonLocked,
            credentialsNonExpired: domainModel.credentialsNonExpired,
            emailVerified: domainModel.emailVerified,
            emailVerifiedAt: domainModel.emailVerifiedAt,
            isVerified: domainModel.isVerified,
            isPrivate: domainModel.isPrivate,
            isPro: domainModel.isPro,
            canAccessProFeatures: domainModel.canAccessProFeatures,
            proSeller: domainModel.proSeller,
            isActiveSellerProfile: domainModel.isActiveSellerProfile,
            isSellingActive: domainModel.isSellingActive,
            individualUser: domainModel.individualUser,
            admin: domainModel.admin,
            role: domainModel.role,
            roleDescription: domainModel.roleDescription,
            roleId: domainModel.roleId,
            hasProfileImage: domainModel.hasProfileImage,
            hasCoverImage: domainModel.hasCoverImage,
            activeImageCount: domainModel.activeImageCount,
            followersCount: domainModel.followersCount,
            followingCount: domainModel.followingCount,
            postsCount: domainModel.postsCount,
            purchasesCount: domainModel.purchasesCount,
            createdAt: domainModel.createdAt,
            createdBy: domainModel.createdBy,
            lastActivityAt: domainModel.lastActivityAt,
            imageCapabilities: domainModel.imageCapabilities.map { ImageCapabilitiesMapper.toDTO(from: $0) },
            maxProfileImageSizeMB: domainModel.maxProfileImageSizeMB,
            maxCoverImageSizeMB: domainModel.maxCoverImageSizeMB
        )
    }
}

struct ImageCapabilitiesMapper: DTOMapper {
    typealias DTO = ImageCapabilitiesDTO
    typealias DomainModel = ImageCapabilities
    
    static func toDomainModel(from dto: ImageCapabilitiesDTO) -> ImageCapabilities {
        return ImageCapabilities(
            canUploadProfileImage: dto.canUploadProfileImage,
            canUploadCoverImage: dto.canUploadCoverImage,
            maxProfileImageSize: dto.maxProfileImageSize,
            maxProfileImageSizeMB: dto.maxProfileImageSizeMB,
            maxCoverImageSize: dto.maxCoverImageSize,
            maxCoverImageSizeMB: dto.maxCoverImageSizeMB
        )
    }
    
    static func toDTO(from domainModel: ImageCapabilities) -> ImageCapabilitiesDTO {
        return ImageCapabilitiesDTO(
            canUploadProfileImage: domainModel.canUploadProfileImage,
            canUploadCoverImage: domainModel.canUploadCoverImage,
            maxProfileImageSize: domainModel.maxProfileImageSize,
            maxProfileImageSizeMB: domainModel.maxProfileImageSizeMB,
            maxCoverImageSize: domainModel.maxCoverImageSize,
            maxCoverImageSizeMB: domainModel.maxCoverImageSizeMB
        )
    }
}

// MARK: - Post Mappers (New with Generic)
struct PostResponseMapper {
    static func toDomainModel(from dto: PostResponseDTO) -> PostResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { postDataDTO in
            PostMapper.toDomainModel(from: postDataDTO)
        }
    }
}

struct PostListResponseMapper {
    static func toDomainModel(from dto: PostListResponseDTO) -> PostListResponse {
        return ApiResponseMapper.toDomainModel(from: dto) { postListDataDTO in
            PostListDataMapper.toDomainModel(from: postListDataDTO)
        }
    }
}

struct PostListDataMapper: DTOMapper {
    typealias DTO = PostListDataDTO
    typealias DomainModel = PostListData
    
    static func toDomainModel(from dto: PostListDataDTO) -> PostListData {
        return PostListData(
            content: dto.content.map { PostMapper.toDomainModel(from: $0) },
            totalElements: dto.totalElements,
            totalPages: dto.totalPages,
            currentPage: dto.currentPage,
            size: dto.size
        )
    }
    
    static func toDTO(from domainModel: PostListData) -> PostListDataDTO {
        return PostListDataDTO(
            content: domainModel.content.map { PostMapper.toDTO(from: $0) },
            totalElements: domainModel.totalElements,
            totalPages: domainModel.totalPages,
            currentPage: domainModel.currentPage,
            size: domainModel.size
        )
    }
}

struct PostMapper: DTOMapper {
    typealias DTO = PostDataDTO
    typealias DomainModel = Post
    
    static func toDomainModel(from dto: PostDataDTO) -> Post {
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
    
    static func toDTO(from domainModel: Post) -> PostDataDTO {
        return PostDataDTO(
            id: domainModel.id,
            title: domainModel.title,
            content: domainModel.content,
            authorId: domainModel.authorId,
            categoryId: domainModel.categoryId,
            visibility: domainModel.visibility.rawValue,
            publishedAt: domainModel.publishedAt.map { DateFormatter.iso8601.string(from: $0) },
            createdAt: DateFormatter.iso8601.string(from: domainModel.createdAt),
            updatedAt: DateFormatter.iso8601.string(from: domainModel.updatedAt),
            likesCount: domainModel.likesCount,
            commentsCount: domainModel.commentsCount,
            sharesCount: domainModel.sharesCount,
            location: domainModel.location,
            latitude: domainModel.latitude,
            longitude: domainModel.longitude,
            hashtags: domainModel.hashtags,
            mediaUrls: domainModel.mediaUrls
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

// MARK: - Location Mapper (Complete)
struct LocationMapper: DTOMapper {
    typealias DTO = LocationDataDTO
    typealias DomainModel = Location
    
    static func toDomainModel(from dto: LocationDataDTO) -> Location {
        return Location(
            latitude: dto.latitude,
            longitude: dto.longitude,
            country: dto.country,
            city: dto.city,
            state: dto.state,
            address: dto.address,
            postalCode: dto.postalCode,
            timezone: dto.timezone,
            source: dto.source,
            accuracy: LocationAccuracy(rawValue: dto.accuracy) ?? .unknown,
            detected: dto.detected
        )
    }
    
    static func toDTO(from domainModel: Location) -> LocationDataDTO {
        return LocationDataDTO(
            latitude: domainModel.latitude,
            longitude: domainModel.longitude,
            country: domainModel.country,
            city: domainModel.city,
            state: domainModel.state,
            address: domainModel.address,
            postalCode: domainModel.postalCode,
            timezone: domainModel.timezone,
            source: domainModel.source,
            accuracy: domainModel.accuracy.rawValue,
            detected: domainModel.detected
        )
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
