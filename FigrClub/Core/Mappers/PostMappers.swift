//
//  PostMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Post Mappers
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
