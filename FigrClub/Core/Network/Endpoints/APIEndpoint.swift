//
//  APIEndpoint.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - HTTPMethod Extension
extension HTTPMethod {
    static let get = HTTPMethod.GET
    static let post = HTTPMethod.POST
    static let put = HTTPMethod.PUT
    static let delete = HTTPMethod.DELETE
    static let patch = HTTPMethod.PATCH
}

// MARK: - API Endpoint
enum APIEndpoint {
    // MARK: - Authentication
    case login
    case register
    case logout
    case refreshToken
    case forgotPassword
    case resetPassword
    
    // MARK: - User Management
    case getCurrentUser
    case getUserById(Int)
    case updateUser(Int)
    case getUserStats(Int)
    case getFollowers(userId: Int, page: Int, size: Int)
    case getFollowing(userId: Int, page: Int, size: Int)
    case followUser(Int)
    case unfollowUser(Int)
    
    // MARK: - Posts
    case publicFeed(page: Int, size: Int)
    case userPosts(userId: Int, page: Int, size: Int)
    case getPost(Int)
    case createPost
    case updatePost(Int)
    case deletePost(Int)
    case likePost(Int)
    case unlikePost(Int)
    
    // MARK: - Comments
    case getComments(postId: Int, page: Int, size: Int)
    case createComment
    case updateComment(Int)
    case deleteComment(Int)
    case likeComment(Int)
    case unlikeComment(Int)
    
    // MARK: - Marketplace
    case marketplaceItems(page: Int, size: Int)
    case getMarketplaceItem(Int)
    case createMarketplaceItem
    case updateMarketplaceItem(Int)
    case deleteMarketplaceItem(Int)
    case searchMarketplaceItems(query: String, page: Int, size: Int)
    case getMarketplaceItemsByCategory(categoryId: Int, page: Int, size: Int)
    case favoriteMarketplaceItem(Int)
    case unfavoriteMarketplaceItem(Int)
    
    // MARK: - Categories
    case getCategories
    case getCategory(Int)
    
    // MARK: - Notifications
    case getNotifications(page: Int, size: Int)
    case markNotificationAsRead(Int)
    case markAllNotificationsAsRead
    case deleteNotification(Int)
    case getUnreadNotificationsCount
    
    // MARK: - Device Tokens & Push Notifications
    case registerDeviceToken
    case getDeviceTokens
    case updateNotificationPreferences(String)
    case testNotification
    
    // MARK: - File Upload
    case uploadImage
    case uploadVideo
    case deleteFile(String)
}

// MARK: - Endpoint Configuration
extension APIEndpoint {
    
    var path: String {
        switch self {
            // Authentication
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/auth/refresh"
        case .forgotPassword:
            return "/auth/forgot-password"
        case .resetPassword:
            return "/auth/reset-password"
            
            // User Management
        case .getCurrentUser:
            return "/users/me"
        case .getUserById(let id):
            return "/users/\(id)"
        case .updateUser(let id):
            return "/users/\(id)"
        case .getUserStats(let id):
            return "/users/\(id)/stats"
        case .getFollowers(let userId, let page, let size):
            return "/users/\(userId)/followers?page=\(page)&size=\(size)"
        case .getFollowing(let userId, let page, let size):
            return "/users/\(userId)/following?page=\(page)&size=\(size)"
        case .followUser(let id):
            return "/users/\(id)/follow"
        case .unfollowUser(let id):
            return "/users/\(id)/unfollow"
            
            // Posts
        case .publicFeed(let page, let size):
            return "/posts/feed?page=\(page)&size=\(size)"
        case .userPosts(let userId, let page, let size):
            return "/users/\(userId)/posts?page=\(page)&size=\(size)"
        case .getPost(let id):
            return "/posts/\(id)"
        case .createPost:
            return "/posts"
        case .updatePost(let id):
            return "/posts/\(id)"
        case .deletePost(let id):
            return "/posts/\(id)"
        case .likePost(let id):
            return "/posts/\(id)/like"
        case .unlikePost(let id):
            return "/posts/\(id)/unlike"
            
            // Comments
        case .getComments(let postId, let page, let size):
            return "/posts/\(postId)/comments?page=\(page)&size=\(size)"
        case .createComment:
            return "/comments"
        case .updateComment(let id):
            return "/comments/\(id)"
        case .deleteComment(let id):
            return "/comments/\(id)"
        case .likeComment(let id):
            return "/comments/\(id)/like"
        case .unlikeComment(let id):
            return "/comments/\(id)/unlike"
            
            // Marketplace
        case .marketplaceItems(let page, let size):
            return "/marketplace/items?page=\(page)&size=\(size)"
        case .getMarketplaceItem(let id):
            return "/marketplace/items/\(id)"
        case .createMarketplaceItem:
            return "/marketplace/items"
        case .updateMarketplaceItem(let id):
            return "/marketplace/items/\(id)"
        case .deleteMarketplaceItem(let id):
            return "/marketplace/items/\(id)"
        case .searchMarketplaceItems(let query, let page, let size):
            return "/marketplace/items/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&page=\(page)&size=\(size)"
        case .getMarketplaceItemsByCategory(let categoryId, let page, let size):
            return "/marketplace/items/category/\(categoryId)?page=\(page)&size=\(size)"
        case .favoriteMarketplaceItem(let id):
            return "/marketplace/items/\(id)/favorite"
        case .unfavoriteMarketplaceItem(let id):
            return "/marketplace/items/\(id)/favorite"
            
            // Categories
        case .getCategories:
            return "/categories"
        case .getCategory(let id):
            return "/categories/\(id)"
            
            // Notifications
        case .getNotifications(let page, let size):
            return "/notifications?page=\(page)&size=\(size)"
        case .markNotificationAsRead(let id):
            return "/notifications/\(id)/read"
        case .markAllNotificationsAsRead:
            return "/notifications/mark-all-read"
        case .deleteNotification(let id):
            return "/notifications/\(id)"
        case .getUnreadNotificationsCount:
            return "/notifications/unread-count"
            
            // Device Tokens & Push Notifications
        case .registerDeviceToken:
            return "/device-tokens"
        case .getDeviceTokens:
            return "/device-tokens"
        case .updateNotificationPreferences(let token):
            return "/device-tokens/\(token)/preferences"
        case .testNotification:
            return "/notifications/test"
            
            // File Upload
        case .uploadImage:
            return "/files/upload/image"
        case .uploadVideo:
            return "/files/upload/video"
        case .deleteFile(let fileId):
            return "/files/\(fileId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .refreshToken, .forgotPassword, .resetPassword,
                .createPost, .createComment, .createMarketplaceItem,
                .followUser, .likePost, .likeComment, .favoriteMarketplaceItem,
                .registerDeviceToken, .testNotification, .uploadImage, .uploadVideo:
            return .POST
            
        case .updateUser, .updatePost, .updateComment, .updateMarketplaceItem,
                .updateNotificationPreferences:
            return .PUT
            
        case .deletePost, .deleteComment, .deleteMarketplaceItem,
                .unfollowUser, .unlikePost, .unlikeComment, .unfavoriteMarketplaceItem,
                .deleteNotification, .deleteFile, .logout:
            return .DELETE
            
        case .markNotificationAsRead, .markAllNotificationsAsRead:
            return .PATCH
            
        default:
            return .GET
        }
    }
    
    var requiresAuthentication: Bool {
        switch self {
        case .login, .register, .forgotPassword, .resetPassword,
                .publicFeed, .getPost, .getComments,
                .marketplaceItems, .getMarketplaceItem, .searchMarketplaceItems,
                .getMarketplaceItemsByCategory, .getCategories, .getCategory,
                .getUserById, .userPosts, .getFollowers, .getFollowing:
            return false
        default:
            return true
        }
    }
    
    var contentType: String {
        switch self {
        case .uploadImage, .uploadVideo:
            return "multipart/form-data"
        default:
            return "application/json"
        }
    }
}

// MARK: - Base URL Configuration
extension APIEndpoint {
    static var baseURL: String {
#if DEBUG
        return AppConfig.API.baseURL
#else
        return AppConfig.API.baseURL
#endif
    }
    
    var fullURL: String {
        return Self.baseURL + path
    }
}

// MARK: - Request Headers
extension APIEndpoint {
    var headers: [String: String] {
        var headers = [String: String]()
        
        // Content-Type
        headers["Content-Type"] = contentType
        
        // Accept
        headers["Accept"] = "application/json"
        
        // User-Agent
        headers["User-Agent"] = "FigrClub-iOS/\(AppConfig.AppInfo.version)"
        
        // API Version
        headers["API-Version"] = "v1"
        
        // Platform
        headers["X-Platform"] = "iOS"
        headers["X-App-Version"] = AppConfig.AppInfo.version
        headers["X-Build-Number"] = AppConfig.AppInfo.buildNumber
        
        return headers
    }
}

// MARK: - Cache Policy
extension APIEndpoint {
    var cachePolicy: URLRequest.CachePolicy {
        switch self {
        case .publicFeed, .marketplaceItems, .getCategories:
            return .returnCacheDataElseLoad
        case .getCurrentUser, .getUserById:
            return .reloadRevalidatingCacheData
        default:
            return .reloadIgnoringLocalCacheData
        }
    }
    
    var timeout: TimeInterval {
        switch self {
        case .uploadImage, .uploadVideo:
            return 60.0 // 1 minute for file uploads
        case .createPost, .createMarketplaceItem:
            return 30.0 // 30 seconds for creation
        default:
            return 15.0 // 15 seconds default
        }
    }
}

// MARK: - API Versioning
enum APIVersion: String {
    case v1 = "v1"
    case v2 = "v2"
    
    var path: String {
        return "/api/\(rawValue)"
    }
}

// MARK: - Environment Configuration
enum APIEnvironment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:9092/figrclub/api/v1"
        case .staging:
            return "http://localhost:9092/figrclub/api/v1"
        case .production:
            return "http://localhost:9092/figrclub/api/v1"
        }
    }
}

// MARK: - Request Configuration
struct RequestConfiguration {
    let endpoint: APIEndpoint
    let version: APIVersion
    let environment: APIEnvironment
    
    var fullURL: String {
        return environment.baseURL + version.path + endpoint.path
    }
    
    static let `default` = RequestConfiguration(
        endpoint: .getCurrentUser,
        version: .v1,
        environment: .production
    )
}

// MARK: - Rate Limiting
extension APIEndpoint {
    var rateLimit: RateLimit? {
        switch self {
        case .login, .register:
            return RateLimit(maxRequests: 5, timeWindow: 300) // 5 requests per 5 minutes
        case .createPost, .createComment:
            return RateLimit(maxRequests: 10, timeWindow: 60) // 10 requests per minute
        case .uploadImage, .uploadVideo:
            return RateLimit(maxRequests: 20, timeWindow: 3600) // 20 uploads per hour
        default:
            return nil
        }
    }
}

struct RateLimit {
    let maxRequests: Int
    let timeWindow: TimeInterval // in seconds
}

// MARK: - Request Priority
extension APIEndpoint {
    var priority: RequestPriority {
        switch self {
        case .getCurrentUser, .refreshToken:
            return .high
        case .getNotifications, .markNotificationAsRead:
            return .high
        case .publicFeed, .marketplaceItems:
            return .normal
        case .uploadImage, .uploadVideo:
            return .low
        default:
            return .normal
        }
    }
}

enum RequestPriority: Int {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}

// MARK: - Request Retry Configuration
extension APIEndpoint {
    var retryConfiguration: RetryConfiguration {
        switch self {
        case .login, .register, .refreshToken:
            return RetryConfiguration(maxAttempts: 2, baseDelay: 1.0)
        case .uploadImage, .uploadVideo:
            return RetryConfiguration(maxAttempts: 3, baseDelay: 2.0)
        case .createPost, .createComment, .createMarketplaceItem:
            return RetryConfiguration(maxAttempts: 2, baseDelay: 1.5)
        default:
            return RetryConfiguration(maxAttempts: 3, baseDelay: 1.0)
        }
    }
}

struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let backoffMultiplier: Double
    let maxDelay: TimeInterval
    
    init(maxAttempts: Int, baseDelay: TimeInterval, backoffMultiplier: Double = 2.0, maxDelay: TimeInterval = 30.0) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.backoffMultiplier = backoffMultiplier
        self.maxDelay = maxDelay
    }
    
    func delayForAttempt(_ attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(backoffMultiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Request Validation
extension APIEndpoint {
    func validateEndpoint() throws {
        switch self {
        case .getUserById(let id), .updateUser(let id), .getUserStats(let id),
                .getPost(let id), .updatePost(let id), .deletePost(let id),
                .likePost(let id), .unlikePost(let id), .followUser(let id),
                .unfollowUser(let id), .getMarketplaceItem(let id),
                .updateMarketplaceItem(let id), .deleteMarketplaceItem(let id),
                .favoriteMarketplaceItem(let id), .unfavoriteMarketplaceItem(let id),
                .getCategory(let id), .updateComment(let id), .deleteComment(let id),
                .likeComment(let id), .unlikeComment(let id),
                .markNotificationAsRead(let id), .deleteNotification(let id):
            guard id > 0 else {
                throw APIError(
                    message: "Invalid ID parameter",
                    code: "INVALID_ID"
                )
            }
            
            // Validación separada para deleteFile que usa String
        case .deleteFile(let fileId):
            guard !fileId.isEmpty else {
                throw APIError(
                    message: "Invalid file ID parameter",
                    code: "INVALID_FILE_ID"
                )
            }
            
        case .getFollowers(let userId, _, _), .getFollowing(let userId, _, _),
                .userPosts(let userId, _, _):
            guard userId > 0 else {
                throw APIError(
                    message: "Invalid user ID parameter",
                    code: "INVALID_USER_ID"
                )
            }
            
        case .getComments(let postId, _, _):
            guard postId > 0 else {
                throw APIError(
                    message: "Invalid post ID parameter",
                    code: "INVALID_POST_ID"
                )
            }
            
        case .getMarketplaceItemsByCategory(let categoryId, _, _):
            guard categoryId > 0 else {
                throw APIError(
                    message: "Invalid category ID",
                    code: "INVALID_CATEGORY_ID"
                )
            }
            
        case .searchMarketplaceItems(let query, _, _):
            guard !query.isEmpty else {
                throw APIError(
                    message: "Search query cannot be empty",
                    code: "EMPTY_QUERY"
                )
            }
            
        default:
            break
        }
    }
}

// MARK: - APIEndpoint Query Parameters Extension
extension APIEndpoint {
    var queryParameters: [String: Any]? {
        switch self {
        case .publicFeed(let page, let size),
                .userPosts(_, let page, let size),
                .getFollowers(_, let page, let size),
                .getFollowing(_, let page, let size),
                .marketplaceItems(let page, let size),
                .getComments(_, let page, let size),
                .getNotifications(let page, let size),
                .getMarketplaceItemsByCategory(_, let page, let size):
            return ["page": page, "size": size]
            
        case .searchMarketplaceItems(let query, let page, let size):
            return ["q": query, "page": page, "size": size]
            
        default:
            return nil
        }
    }
}

enum RequestValidationResult {
    case valid
    case invalid([RequestValidationError])
}

enum RequestValidationError: Error {
    case invalidURL
    case invalidMethod
    case missingAuthentication
    case missingContentType
    case invalidBody
}

// MARK: - Mock Configuration (for testing)
#if DEBUG
extension APIEndpoint {
    var mockResponse: MockResponse? {
        switch self {
        case .login:
            return MockResponse(
                statusCode: 200,
                data: """
                {
                    "authToken": {"token": "mock_token"},
                    "userId": 1,
                    "expiresAt": "2024-12-31T23:59:59Z"
                }
                """.data(using: .utf8)!
            )
        case .getCurrentUser:
            return MockResponse(
                statusCode: 200,
                data: """
                {
                    "id": 1,
                    "firstName": "Mock",
                    "lastName": "User",
                    "email": "mock@example.com",
                    "username": "mockuser"
                }
                """.data(using: .utf8)!
            )
        default:
            return nil
        }
    }
}

struct MockResponse {
    let statusCode: Int
    let data: Data
    let headers: [String: String]
    
    init(statusCode: Int, data: Data, headers: [String: String] = [:]) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
    }
}
#endif
