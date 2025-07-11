//
//  DTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation

// MARK: - Base DTOs
protocol BaseDTO: Codable {}

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

typealias AuthResponseDTO = ApiResponseDTO<AuthDataDTO>

struct AuthTokenDTO: BaseDTO {
    let id: Int
    let token: String
}

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
}

struct RoleInfoDTO: BaseDTO {
    let isAdmin: Bool
    let roleModifiable: Bool
    let roleModificationReason: String
    let roleName: String
}

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
}

struct ImageCapabilitiesDTO: BaseDTO {
    let canUploadProfileImage: Bool
    let canUploadCoverImage: Bool
    let maxProfileImageSize: Int
    let maxProfileImageSizeMB: String
    let maxCoverImageSize: Int
    let maxCoverImageSizeMB: String
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
}

typealias PostResponseDTO = ApiResponseDTO<PostDataDTO>

struct PostListDataDTO: BaseDTO {
    let content: [PostDataDTO]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
}

typealias PostListResponseDTO = ApiResponseDTO<PostListDataDTO>

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
}

typealias LocationResponseDTO = ApiResponseDTO<LocationDataDTO>

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

typealias NotificationListResponseDTO = ApiResponseDTO<NotificationListDataDTO>

extension BaseDTO {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert DTO to dictionary"])
        }
        return dictionary
    }
}
