//
//  UserMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

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
    
    // Use toDomainModel() instead - wrapper method removed
    
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
