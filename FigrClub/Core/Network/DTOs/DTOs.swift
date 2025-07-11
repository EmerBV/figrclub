//
//  DTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - Base DTOs
protocol BaseDTO: Codable {}

// MARK: - Base API Response
struct ApiResponseDTO<T: Codable>: BaseDTO {
    let message: String
    let data: T
    let timestamp: String
    let currency: String?
    let locale: String?
    let status: Int?
}

// MARK: - Auth DTOs
struct LoginRequestDTO: BaseDTO {
    let email: String
    let password: String
}

struct AuthDataDTO: BaseDTO {
    let authToken: AuthTokenDTO
    let userId: Int
    let email: String
}

struct AuthTokenDTO: BaseDTO {
    let id: Int
    let token: String
}

typealias AuthResponseDTO = ApiResponseDTO<AuthDataDTO>

struct RegisterRequestDTO: BaseDTO {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let username: String
    let userType: String
    let legalAcceptances: [LegalAcceptanceDTO]
    let consents: [ConsentDTO]
}

struct RegisterDataDTO: BaseDTO {
    let userId: Int
    let email: String
    let fullName: String
    let emailVerified: Bool
    let emailSent: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "userId"
        case email
        case fullName = "fullName"
        case emailVerified = "emailVerified"
        case emailSent = "emailSent"
    }
}

typealias RegisterResponseDTO = ApiResponseDTO<RegisterDataDTO>

struct LegalAcceptanceDTO: BaseDTO {
    let documentType: String
    let acceptedAt: String
    
    enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case acceptedAt = "accepted_at"
    }
}

struct ConsentDTO: BaseDTO {
    let consentType: String
    let isGranted: Bool
    
    enum CodingKeys: String, CodingKey {
        case consentType = "consent_type"
        case isGranted = "is_granted"
    }
}

// MARK: - User DTOs (Refactored)
struct UserResponseDataDTO: BaseDTO {
    let roleInfo: RoleInfoDTO
    let user: UserDTO
}

typealias UserResponseDTO = ApiResponseDTO<UserResponseDataDTO>

struct UserUpdateRequestDTO: BaseDTO {
    let firstName: String?
    let lastName: String?
    let bio: String?
    let city: String?
    let country: String?
    let phone: String?
    let isPrivate: Bool?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "firstName"
        case lastName = "lastName"
        case bio, city, country, phone
        case isPrivate = "isPrivate"
    }
}

struct RoleInfoDTO: BaseDTO {
    let isAdmin: Bool
    let roleModifiable: Bool
    let roleModificationReason: String
    let roleName: String
    
    enum CodingKeys: String, CodingKey {
        case isAdmin = "is_admin"
        case roleModifiable = "role_modifiable"
        case roleModificationReason = "role_modification_reason"
        case roleName = "role_name"
    }
}

struct UserDTO: BaseDTO {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let displayName: String
    let fullName: String
    let birthDate: String?
    let city: String?
    let country: String?
    let phone: String?
    let preferredLanguage: String?
    let active: Bool
    let enabled: Bool
    let accountNonExpired: Bool
    let accountNonLocked: Bool
    let credentialsNonExpired: Bool
    let emailVerified: Bool
    let emailVerifiedAt: String?
    let isVerified: Bool
    let isPrivate: Bool
    let isPro: Bool
    let canAccessProFeatures: Bool
    let proSeller: Bool
    let isActiveSellerProfile: Bool
    let isSellingActive: Bool
    let individualUser: Bool
    let admin: Bool
    let role: String
    let roleDescription: String?
    let roleId: Int
    let hasProfileImage: Bool
    let hasCoverImage: Bool
    let activeImageCount: Int
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let purchasesCount: Int
    let createdAt: String
    let createdBy: String?
    let lastActivityAt: String?
    let imageCapabilities: ImageCapabilitiesDTO?
    let maxProfileImageSizeMB: String?
    let maxCoverImageSizeMB: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case displayName = "display_name"
        case fullName = "full_name"
        case birthDate = "birth_date"
        case city, country, phone
        case preferredLanguage = "preferred_language"
        case active, enabled
        case accountNonExpired = "account_non_expired"
        case accountNonLocked = "account_non_locked"
        case credentialsNonExpired = "credentials_non_expired"
        case emailVerified = "email_verified"
        case emailVerifiedAt = "email_verified_at"
        case isVerified = "is_verified"
        case isPrivate = "is_private"
        case isPro = "is_pro"
        case canAccessProFeatures = "can_access_pro_features"
        case proSeller = "pro_seller"
        case isActiveSellerProfile = "is_active_seller_profile"
        case isSellingActive = "is_selling_active"
        case individualUser = "individual_user"
        case admin
        case role
        case roleDescription = "role_description"
        case roleId = "role_id"
        case hasProfileImage = "has_profile_image"
        case hasCoverImage = "has_cover_image"
        case activeImageCount = "active_image_count"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case postsCount = "posts_count"
        case purchasesCount = "purchases_count"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case lastActivityAt = "last_activity_at"
        case imageCapabilities = "image_capabilities"
        case maxProfileImageSizeMB = "max_profile_image_size_mb"
        case maxCoverImageSizeMB = "max_cover_image_size_mb"
    }
}

struct ImageCapabilitiesDTO: BaseDTO {
    let canUploadProfileImage: Bool
    let canUploadCoverImage: Bool
    let maxProfileImageSize: Int
    let maxProfileImageSizeMB: String
    let maxCoverImageSize: Int
    let maxCoverImageSizeMB: String
    
    enum CodingKeys: String, CodingKey {
        case canUploadProfileImage = "can_upload_profile_image"
        case canUploadCoverImage = "can_upload_cover_image"
        case maxProfileImageSize = "max_profile_image_size"
        case maxProfileImageSizeMB = "max_profile_image_size_mb"
        case maxCoverImageSize = "max_cover_image_size"
        case maxCoverImageSizeMB = "max_cover_image_size_mb"
    }
}

// MARK: - Post DTOs
struct PostDataDTO: BaseDTO {
    let id: Int
    let title: String
    let content: String
    let authorId: Int
    let categoryId: Int
    let visibility: String
    let publishedAt: String?
    let createdAt: String
    let updatedAt: String
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let hashtags: [String]
    let mediaUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, title, content
        case authorId = "author_id"
        case categoryId = "category_id"
        case visibility
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case sharesCount = "shares_count"
        case location, latitude, longitude, hashtags
        case mediaUrls = "media_urls"
    }
}

typealias PostResponseDTO = ApiResponseDTO<PostDataDTO>
typealias PostListResponseDTO = ApiResponseDTO<PostListDataDTO>

struct PostListDataDTO: BaseDTO {
    let content: [PostDataDTO]
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
typealias MarketplaceItemListResponseDTO = ApiResponseDTO<MarketplaceItemListDataDTO>

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

// MARK: - Location DTOs
struct LocationDataDTO: BaseDTO {
    let latitude: Double
    let longitude: Double
    let country: String
    let city: String
    let state: String?
    let address: String
    let postalCode: String?
    let timezone: String
    let source: String
    let accuracy: String
    let detected: Bool
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, country, city, state, address
        case postalCode = "postal_code"
        case timezone, source, accuracy, detected
    }
}

typealias LocationResponseDTO = ApiResponseDTO<LocationDataDTO>

// MARK: - Notification DTOs
struct NotificationDataDTO: BaseDTO {
    let id: Int
    let userId: Int
    let title: String
    let message: String
    let type: String
    let isRead: Bool
    let createdAt: String
    let actionUrl: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, message, type
        case isRead = "is_read"
        case createdAt = "created_at"
        case actionUrl = "action_url"
        case metadata
    }
}

typealias NotificationResponseDTO = ApiResponseDTO<NotificationDataDTO>
typealias NotificationListResponseDTO = ApiResponseDTO<NotificationListDataDTO>

struct NotificationListDataDTO: BaseDTO {
    let content: [NotificationDataDTO]
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

// MARK: - Error Response (Generic)
struct ErrorDetailsDTO: BaseDTO {
    let message: String
    let code: String?
    let details: [String]?
    let path: String?
    let status: Int?
}

typealias ErrorResponseDTO = ApiResponseDTO<ErrorDetailsDTO>

// MARK: - Empty Response for operations without data
struct EmptyDataDTO: BaseDTO {
    let success: Bool?
    
    init() {
        self.success = true
    }
}

// ✅ Para operaciones como logout, delete, etc.
typealias EmptyResponseDTO = ApiResponseDTO<EmptyDataDTO>

extension BaseDTO {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert DTO to dictionary"])
        }
        return dictionary
    }
}
