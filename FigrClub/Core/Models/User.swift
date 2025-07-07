//
//  User.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let username: String
    let fullName: String?
    let profileImageURL: String?
    let bio: String?
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
