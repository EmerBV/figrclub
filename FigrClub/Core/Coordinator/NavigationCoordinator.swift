//
//  NavigationCoordinator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import Foundation
import UIKit

// MARK: - Navigation Coordinator
@MainActor
class NavigationCoordinator: ObservableObject {
    // Estados de navegación modal/sheet
    @Published var showingProfileSearch = false
    @Published var showingPostDetail = false
    @Published var showingPostOptions = false
    @Published var showingPostComments = false
    @Published var showingUserProfile = false
    @Published var showingUserProfileDetail = false
    @Published var showingSettings = false
    @Published var showingEditProfile = false
    @Published var showingCreatePost = false
    @Published var showingProductDetail = false
    @Published var selectedProduct: MarketplaceProduct?
    
    // IDs para navegación
    @Published var selectedPostId: String?
    @Published var selectedUserId: String?
    @Published var selectedUserForDetail: User?
    
    // Estado de la navegación
    private var navigationStack: [String] = []
    
    // MARK: - Navigation Methods
    func showProfileSearch() {
        Logger.info("🧭 NavigationCoordinator: Showing profile search")
        showingProfileSearch = true
        trackNavigation("profileSearch")
    }
    
    func showPostDetail(_ postId: String) {
        Logger.info("🧭 NavigationCoordinator: Showing post detail: \(postId)")
        selectedPostId = postId
        showingPostDetail = true
        trackNavigation("postDetail_\(postId)")
    }
    
    func showPostOptions() {
        Logger.info("🧭 NavigationCoordinator: Showing post options")
        showingPostOptions = true
        trackNavigation("postOptions")
    }
    
    func showPostComments() {
        Logger.info("🧭 NavigationCoordinator: Showing post comments")
        showingPostComments = true
        trackNavigation("postComments")
    }
    
    func showUserProfile(_ userId: String) {
        Logger.info("🧭 NavigationCoordinator: Showing user profile: \(userId)")
        selectedUserId = userId
        showingUserProfile = true
        trackNavigation("userProfile_\(userId)")
    }
    
    func showUserProfileDetail(user: User) {
        Logger.info("🧭 NavigationCoordinator: Presenting user profile detail: \(user.displayName)")
        selectedUserForDetail = user
        showingUserProfileDetail = true
        trackNavigation("userProfileDetail_\(user.id)")
    }
    
    func showSettings() {
        Logger.info("🧭 NavigationCoordinator: Showing settings")
        showingSettings = true
        trackNavigation("settings")
    }
    
    func showEditProfile() {
        Logger.info("🧭 NavigationCoordinator: Showing edit profile")
        showingEditProfile = true
        trackNavigation("editProfile")
    }
    
    func showCreatePost() {
        Logger.info("🧭 NavigationCoordinator: Showing create post")
        showingCreatePost = true
        trackNavigation("createPost")
    }
    
    func showProductDetail(_ product: MarketplaceProduct) {
        Logger.info("🧭 NavigationCoordinator: Showing product detail: \(product.title)")
        selectedProduct = product
        showingProductDetail = true
        trackNavigation("productDetail_\(product.id)")
    }
    
    // MARK: - Dismiss Methods
    func dismissProfileSearch() {
        Logger.info("🧭 NavigationCoordinator: Dismissing profile search")
        showingProfileSearch = false
        removeFromNavigationStack("profileSearch")
    }
    
    func dismissPostDetail() {
        Logger.info("🧭 NavigationCoordinator: Dismissing post detail")
        showingPostDetail = false
        selectedPostId = nil
        removeFromNavigationStack("postDetail")
    }
    
    func dismissPostOptions() {
        Logger.info("🧭 NavigationCoordinator: Dismissing post options")
        showingPostOptions = false
        removeFromNavigationStack("postOptions")
    }
    
    func dismissPostComments() {
        Logger.info("🧭 NavigationCoordinator: Dismissing post comments")
        showingPostComments = false
        removeFromNavigationStack("postComments")
    }
    
    func dismissUserProfile() {
        Logger.info("🧭 NavigationCoordinator: Dismissing user profile")
        showingUserProfile = false
        selectedUserId = nil
        removeFromNavigationStack("userProfile")
    }
    
    func dismissUserProfileDetail() {
        Logger.info("🧭 NavigationCoordinator: Dismissing user profile detail")
        showingUserProfileDetail = false
        selectedUserForDetail = nil
        removeFromNavigationStack("userProfileDetail")
    }
    
    func dismissSettings() {
        Logger.info("🧭 NavigationCoordinator: Dismissing settings")
        showingSettings = false
        removeFromNavigationStack("settings")
    }
    
    func dismissEditProfile() {
        Logger.info("🧭 NavigationCoordinator: Dismissing edit profile")
        showingEditProfile = false
        removeFromNavigationStack("editProfile")
    }
    
    func dismissCreatePost() {
        Logger.info("🧭 NavigationCoordinator: Dismissing create post")
        showingCreatePost = false
        removeFromNavigationStack("createPost")
    }
    
    func dismissProductDetail() {
        Logger.info("🧭 NavigationCoordinator: Dismissing product detail")
        showingProductDetail = false
        selectedProduct = nil
        removeFromNavigationStack("productDetail")
    }
    
    func dismissAll() {
        Logger.info("🧭 NavigationCoordinator: Dismissing all presentations")
        
        showingProfileSearch = false
        showingPostDetail = false
        showingPostOptions = false
        showingPostComments = false
        showingUserProfile = false
        showingUserProfileDetail = false
        showingSettings = false
        showingEditProfile = false
        showingCreatePost = false
        showingProductDetail = false
        
        selectedPostId = nil
        selectedUserId = nil
        selectedUserForDetail = nil
        selectedProduct = nil
        
        navigationStack.removeAll()
    }
    
    // MARK: - Navigation Stack Management
    private func trackNavigation(_ identifier: String) {
        navigationStack.append(identifier)
        Logger.debug("🧭 NavigationCoordinator: Navigation stack: \(navigationStack)")
    }
    
    private func removeFromNavigationStack(_ prefix: String) {
        navigationStack.removeAll { $0.hasPrefix(prefix) }
        Logger.debug("🧭 NavigationCoordinator: Navigation stack after removal: \(navigationStack)")
    }
    
    // MARK: - State Queries
    var hasActiveNavigation: Bool {
        return showingProfileSearch ||
        showingPostDetail ||
        showingPostOptions ||
        showingPostComments ||
        showingUserProfile ||
        showingUserProfileDetail ||
        showingSettings ||
        showingEditProfile ||
        showingCreatePost ||
        showingProductDetail
    }
    
    var currentNavigationCount: Int {
        return navigationStack.count
    }
    
    // MARK: - Navigation History
    func canGoBack() -> Bool {
        return !navigationStack.isEmpty
    }
    
    func goBack() {
        guard !navigationStack.isEmpty else {
            Logger.warning("🧭 NavigationCoordinator: Cannot go back - navigation stack is empty")
            return
        }
        
        let lastNavigation = navigationStack.removeLast()
        Logger.info("🧭 NavigationCoordinator: Going back from: \(lastNavigation)")
        
        // Dismiss based on last navigation
        if lastNavigation.hasPrefix("profileSearch") {
            dismissProfileSearch()
        } else if lastNavigation.hasPrefix("postDetail") {
            dismissPostDetail()
        } else if lastNavigation.hasPrefix("postOptions") {
            dismissPostOptions()
        } else if lastNavigation.hasPrefix("postComments") {
            dismissPostComments()
        } else if lastNavigation.hasPrefix("userProfile") {
            dismissUserProfile()
        } else if lastNavigation.hasPrefix("userProfileDetail") {
            dismissUserProfileDetail()
        } else if lastNavigation.hasPrefix("productDetail") {
            dismissProductDetail()
        } else if lastNavigation.hasPrefix("settings") {
            dismissSettings()
        } else if lastNavigation.hasPrefix("editProfile") {
            dismissEditProfile()
        } else if lastNavigation.hasPrefix("createPost") {
            dismissCreatePost()
        }
    }
}

// MARK: - Media Asset Model
struct MediaAsset: Identifiable, Hashable {
    let id = UUID()
    let type: MediaType
    let image: UIImage?
    let videoURL: URL?
    let duration: TimeInterval?
    let createdAt: Date
    
    enum MediaType {
        case photo
        case video
    }
    
    init(image: UIImage) {
        self.type = .photo
        self.image = image
        self.videoURL = nil
        self.duration = nil
        self.createdAt = Date()
    }
    
    init(videoURL: URL, duration: TimeInterval) {
        self.type = .video
        self.image = nil
        self.videoURL = videoURL
        self.duration = duration
        self.createdAt = Date()
    }
    
    // Implementar Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaAsset, rhs: MediaAsset) -> Bool {
        lhs.id == rhs.id
    }
}
