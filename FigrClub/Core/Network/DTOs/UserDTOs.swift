//
//  UserDTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

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
