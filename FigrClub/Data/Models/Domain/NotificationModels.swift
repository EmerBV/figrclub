//
//  NotificationModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation

// MARK: - Notification Models
struct AppNotification: Codable, Identifiable {
    let id: Int
    let title: String
    let message: String
    let type: NotificationType
    let entityType: String?
    let entityId: Int?
    let isRead: Bool
    let createdAt: String
}

enum NotificationType: String, Codable, CaseIterable {
    case like = "LIKE"
    case comment = "COMMENT"
    case follow = "FOLLOW"
    case newPost = "NEW_POST"
    case marketplaceSale = "MARKETPLACE_SALE"
    case marketplaceQuestion = "MARKETPLACE_QUESTION"
    case system = "SYSTEM"
}
