//
//  APIEndpoint+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

extension APIEndpoint {
    /*
    // MARK: - Convenience Static Methods for Common Endpoints
    
    // MARK: - Notifications
    static func getNotifications(page: Int = 0, size: Int = 20) -> APIEndpoint {
        return .getNotifications(page: page, size: size)
    }
    
    static func markNotificationAsRead(_ id: Int) -> APIEndpoint {
        return .markNotificationAsRead(id)
    }
    
    static var markAllNotificationsAsRead: APIEndpoint {
        return .markAllNotificationsAsRead
    }
    
    static func deleteNotification(_ id: Int) -> APIEndpoint {
        return .deleteNotification(id)
    }
    
    // MARK: - User Stats and Posts
    static func getUserStats(_ userId: Int) -> APIEndpoint {
        return .getUserStats(userId)
    }
    
    static func getUserPosts(_ userId: Int, page: Int = 0, size: Int = 20) -> APIEndpoint {
        return .getUserPosts(userId, page: page, size: size)
    }
    
    // MARK: - Social Features
    static func likePost(_ postId: Int) -> APIEndpoint {
        return .likePost(postId)
    }
    
    static func unlikePost(_ postId: Int) -> APIEndpoint {
        return .unlikePost(postId)
    }
    
    static func followUser(_ userId: Int) -> APIEndpoint {
        return .followUser(userId)
    }
    
    static func unfollowUser(_ userId: Int) -> APIEndpoint {
        return .unfollowUser(userId)
    }
    
    // MARK: - Comments
    static func getComments(postId: Int, page: Int = 0, size: Int = 50) -> APIEndpoint {
        return .getComments(postId: postId, page: page, size: size)
    }
     */
}

// MARK: - Additional Response Models for Missing Endpoints

// Simple response for actions that don't return data
struct EmptyResponse: Codable {
    static let success = EmptyResponse()
}

// Response for like/unlike actions
struct LikeResponse: Codable {
    let postId: Int
    let isLiked: Bool
    let likesCount: Int
}

// Response for follow/unfollow actions
struct FollowResponse: Codable {
    let userId: Int
    let isFollowing: Bool
    let followersCount: Int
}
