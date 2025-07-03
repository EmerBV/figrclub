//
//  APIRequest.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let username: String
    let userType: UserType
    let legalAcceptances: [LegalAcceptance]
    let consents: [Consent]
}

struct UpdateUserRequest: Codable {
    let firstName: String?
    let lastName: String?
    let username: String?
    let bio: String?
    let profileImageUrl: String?
}

// MARK: - Page Request Model
struct PageRequest: Codable {
    let page: Int
    let size: Int
    let sort: String?
    
    init(page: Int = 0, size: Int = 20, sort: String? = nil) {
        self.page = page
        self.size = size
        self.sort = sort
    }
}

// MARK: - Create Post Request
struct CreatePostRequest: Codable {
    let title: String
    let content: String
    let categoryId: Int?
    let visibility: PostVisibility
    let publishNow: Bool
    let location: String?
    let hashtags: [String]?
    let imageUrls: [String]?
}

struct CreateMarketplaceItemRequest: Codable {
    let title: String
    let description: String
    let categoryId: Int
    let basePrice: Double
    let currency: String
    let condition: ItemCondition
    let baseStockQuantity: Int
    let negotiable: Bool
    let acceptsOffers: Bool
    let allowsQuestions: Bool
    let freeShipping: Bool
    let pickupAvailable: Bool
    let country: String
    let city: String
    let region: String?
}

struct UpdateNotificationPreferencesRequest: Codable {
    let notificationsEnabled: Bool
    let marketingEnabled: Bool
    let salesEnabled: Bool
    let purchaseEnabled: Bool
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let newPassword: String
}

struct UpdateMarketplaceItemRequest: Codable {
    let title: String?
    let description: String?
    let categoryId: Int?
    let basePrice: Double?
    let condition: ItemCondition?
    let baseStockQuantity: Int?
    let negotiable: Bool?
    let acceptsOffers: Bool?
    let allowsQuestions: Bool?
    let freeShipping: Bool?
    let pickupAvailable: Bool?
    let status: ItemStatus?
}
