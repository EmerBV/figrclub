//
//  PostDTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

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

