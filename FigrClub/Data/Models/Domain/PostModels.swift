//
//  PostModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 1/7/25.
//

import Foundation

// MARK: - Post Models

// MARK: - Image Model
struct PostImage: Codable, Identifiable {
    let id: Int
    let imageUrl: String
    let altText: String?
    let displayOrder: Int
    let imageType: String
    let fileSize: Int
    let width: Int
    let height: Int
}

// MARK: - Video Model
struct PostVideo: Codable, Identifiable {
    let id: Int
    let videoUrl: String
    let thumbnailUrl: String?
    let displayOrder: Int
    let videoType: String
    let fileSize: Int
    let duration: Int?
    let width: Int?
    let height: Int?
}

// MARK: - Post Model (actualizado para coincidir con la API)
struct Post: Codable, Identifiable {
    let id: Int
    let userId: Int
    let userFullName: String
    let userIsVerified: Bool
    let description: String?
    let hashtags: [String]
    let status: PostStatus
    let visibility: PostVisibility
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let savesCount: Int
    let isFeatured: Bool
    let isPinned: Bool
    let commentsEnabled: Bool
    let likesEnabled: Bool
    let publishedAt: String?
    let createdAt: String
    let updatedAt: String?
    let contentUpdatedAt: String?
    let images: [PostImage]
    let videos: [PostVideo]
    
    // MARK: - Computed Properties
    var content: String? {
        return description
    }
    
    var authorId: Int {
        return userId
    }
    
    var title: String {
        // Generar título desde la descripción (primeras palabras)
        guard let desc = description, !desc.isEmpty else {
            return "Post sin título"
        }
        
        let words = desc.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(8)
        
        let title = words.joined(separator: " ")
        return title.count > 50 ? String(title.prefix(47)) + "..." : title
    }
    
    // User interaction flags (opcional)
    var isLikedByCurrentUser: Bool? { return nil }
    var isBookmarkedByCurrentUser: Bool? { return nil }
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
#if DEBUG
        print("🔍 Decoding Post model...")
        print("Available keys: \(container.allKeys.map { $0.stringValue })")
#endif
        
        do {
            id = try container.decode(Int.self, forKey: .id)
            userId = try container.decode(Int.self, forKey: .userId)
            userFullName = try container.decode(String.self, forKey: .userFullName)
            userIsVerified = try container.decodeBool(forKey: .userIsVerified)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            hashtags = try container.decodeIfPresent([String].self, forKey: .hashtags) ?? []
            
            // Decode enums with fallback
            if let statusString = try? container.decode(String.self, forKey: .status) {
                status = PostStatus(rawValue: statusString) ?? .draft
            } else {
                status = .draft
            }
            
            if let visibilityString = try? container.decode(String.self, forKey: .visibility) {
                visibility = PostVisibility(rawValue: visibilityString) ?? .public
            } else {
                visibility = .public
            }
            
            likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
            commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount) ?? 0
            sharesCount = try container.decodeIfPresent(Int.self, forKey: .sharesCount) ?? 0
            savesCount = try container.decodeIfPresent(Int.self, forKey: .savesCount) ?? 0
            isFeatured = try container.decodeBool(forKey: .isFeatured)
            isPinned = try container.decodeBool(forKey: .isPinned)
            commentsEnabled = try container.decodeBool(forKey: .commentsEnabled)
            likesEnabled = try container.decodeBool(forKey: .likesEnabled)
            
            publishedAt = try container.decodeIfPresent(String.self, forKey: .publishedAt)
            createdAt = try container.decode(String.self, forKey: .createdAt)
            updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            contentUpdatedAt = try container.decodeIfPresent(String.self, forKey: .contentUpdatedAt)
            
            images = try container.decodeIfPresent([PostImage].self, forKey: .images) ?? []
            videos = try container.decodeIfPresent([PostVideo].self, forKey: .videos) ?? []
            
#if DEBUG
            print("✅ Post decoded successfully: ID \(id), User: \(userFullName)")
#endif
        } catch {
#if DEBUG
            print("❌ Failed to decode Post: \(error)")
            if let decodingError = error as? DecodingError {
                DebugHelper.printDecodingError(decodingError)
            }
#endif
            throw error
        }
    }
    
    // MARK: - Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(userFullName, forKey: .userFullName)
        try container.encode(userIsVerified, forKey: .userIsVerified)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(hashtags, forKey: .hashtags)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode(visibility.rawValue, forKey: .visibility)
        try container.encode(likesCount, forKey: .likesCount)
        try container.encode(commentsCount, forKey: .commentsCount)
        try container.encode(sharesCount, forKey: .sharesCount)
        try container.encode(savesCount, forKey: .savesCount)
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(commentsEnabled, forKey: .commentsEnabled)
        try container.encode(likesEnabled, forKey: .likesEnabled)
        try container.encodeIfPresent(publishedAt, forKey: .publishedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(contentUpdatedAt, forKey: .contentUpdatedAt)
        try container.encode(images, forKey: .images)
        try container.encode(videos, forKey: .videos)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, userId, userFullName, userIsVerified, description, hashtags
        case status, visibility, likesCount, commentsCount, sharesCount, savesCount
        case isFeatured, isPinned, commentsEnabled, likesEnabled
        case publishedAt, createdAt, updatedAt, contentUpdatedAt
        case images, videos
    }
}

// MARK: - Helper Extension for Bool Decoding
extension KeyedDecodingContainer {
    func decodeBool(forKey key: K) throws -> Bool {
        // Intentar decodificar como Bool primero
        if let boolValue = try? decode(Bool.self, forKey: key) {
            return boolValue
        }
        
        // Si falla, intentar como Int (0 = false, cualquier otro = true)
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue != 0
        }
        
        // Si falla, intentar como String
        if let stringValue = try? decode(String.self, forKey: key) {
            switch stringValue.lowercased() {
            case "true", "1", "yes":
                return true
            case "false", "0", "no":
                return false
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: codingPath + [key],
                        debugDescription: "Cannot decode \(stringValue) as Bool"
                    )
                )
            }
        }
        
        throw DecodingError.keyNotFound(key, DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Cannot decode Bool for key \(key.stringValue)"
        ))
    }
}

// MARK: - Post Status
enum PostStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case published = "PUBLISHED"
    case archived = "ARCHIVED"
    case deleted = "DELETED"
}

// MARK: - Post Visibility
enum PostVisibility: String, Codable, CaseIterable {
    case `public` = "PUBLIC"
    case followers = "FOLLOWERS"
    case `private` = "PRIVATE"
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
}

// MARK: - Extensions for Backward Compatibility
extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Post {
    var imageUrls: [String] {
        return images.map { $0.imageUrl }
    }
    
    var videoUrls: [String] {
        return videos.map { $0.videoUrl }
    }
    
    var hasMedia: Bool {
        return !images.isEmpty || !videos.isEmpty
    }
    
    var mediaCount: Int {
        return images.count + videos.count
    }
    
    var primaryImageUrl: String? {
        return images.first?.imageUrl
    }
    
    var isLongContent: Bool {
        return (description?.count ?? 0) > 300
    }
    
    var shortDescription: String {
        guard let description = description else { return "" }
        if description.count <= 150 {
            return description
        }
        let truncated = String(description.prefix(147))
        return truncated + "..."
    }
}

// MARK: - Paginated Response
struct PaginatedResponse<T: Codable>: Codable {
    let size: Int
    let page: Int
    let totalPages: Int
    let totalElements: Int
    let first: Bool
    let last: Bool
    let content: [T]
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
#if DEBUG
        print("🔍 Decoding PaginatedResponse<\(T.self)>...")
        print("Available keys: \(container.allKeys.map { $0.stringValue })")
#endif
        
        do {
            size = try container.decode(Int.self, forKey: .size)
            page = try container.decode(Int.self, forKey: .page)
            totalPages = try container.decode(Int.self, forKey: .totalPages)
            totalElements = try container.decode(Int.self, forKey: .totalElements)
            
            // Decode booleans with fallback
            first = try container.decodeBool(forKey: .first)
            last = try container.decodeBool(forKey: .last)
            
            content = try container.decode([T].self, forKey: .content)
            
#if DEBUG
            print("✅ PaginatedResponse decoded successfully: \(content.count) items")
#endif
        } catch {
#if DEBUG
            print("❌ Failed to decode PaginatedResponse: \(error)")
            if let decodingError = error as? DecodingError {
                DebugHelper.printDecodingError(decodingError)
            }
#endif
            throw error
        }
    }
    
    // MARK: - Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(size, forKey: .size)
        try container.encode(page, forKey: .page)
        try container.encode(totalPages, forKey: .totalPages)
        try container.encode(totalElements, forKey: .totalElements)
        try container.encode(first, forKey: .first)
        try container.encode(last, forKey: .last)
        try container.encode(content, forKey: .content)
    }
    
    enum CodingKeys: String, CodingKey {
        case size, page, totalPages, totalElements, first, last, content
    }
}



// MARK: - Convenience Extensions
extension PaginatedResponse {
    var isEmpty: Bool {
        return content.isEmpty
    }
    
    var hasNextPage: Bool {
        return !last
    }
    
    var hasPreviousPage: Bool {
        return !first
    }
    
    var nextPage: Int? {
        return hasNextPage ? page + 1 : nil
    }
    
    var previousPage: Int? {
        return hasPreviousPage ? page - 1 : nil
    }
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

// MARK: - Sort Direction
enum SortDirection: String, Codable, CaseIterable {
    case asc = "ASC"
    case desc = "DESC"
}
