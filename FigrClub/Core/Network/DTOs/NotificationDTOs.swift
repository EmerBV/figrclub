//
//  NotificationDTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

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
