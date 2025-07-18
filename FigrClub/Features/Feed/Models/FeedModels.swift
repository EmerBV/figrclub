//
//  FeedModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Domain Models (Using PaginatedData generic type)
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
