//
//  NavigationCoordinator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import Foundation

// MARK: - Navigation Coordinator
@MainActor
class NavigationCoordinator: ObservableObject {
    // Estados de navegación modal/sheet
    @Published var showingPostDetail = false
    @Published var showingUserProfile = false
    @Published var showingSettings = false
    @Published var showingEditProfile = false
    @Published var showingCreatePost = false
    
    // IDs para navegación
    @Published var selectedPostId: String?
    @Published var selectedUserId: String?
    
    // Estado de la navegación
    private var navigationStack: [String] = []
    
    // MARK: - Navigation Methods
    
    func showPostDetail(_ postId: String) {
        Logger.info("🧭 NavigationCoordinator: Showing post detail: \(postId)")
        selectedPostId = postId
        showingPostDetail = true
        trackNavigation("postDetail_\(postId)")
    }
    
    func showUserProfile(_ userId: String) {
        Logger.info("🧭 NavigationCoordinator: Showing user profile: \(userId)")
        selectedUserId = userId
        showingUserProfile = true
        trackNavigation("userProfile_\(userId)")
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
    
    // MARK: - Dismiss Methods
    
    func dismissPostDetail() {
        Logger.info("🧭 NavigationCoordinator: Dismissing post detail")
        showingPostDetail = false
        selectedPostId = nil
        removeFromNavigationStack("postDetail")
    }
    
    func dismissUserProfile() {
        Logger.info("🧭 NavigationCoordinator: Dismissing user profile")
        showingUserProfile = false
        selectedUserId = nil
        removeFromNavigationStack("userProfile")
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
    
    func dismissAll() {
        Logger.info("🧭 NavigationCoordinator: Dismissing all presentations")
        
        showingPostDetail = false
        showingUserProfile = false
        showingSettings = false
        showingEditProfile = false
        showingCreatePost = false
        
        selectedPostId = nil
        selectedUserId = nil
        
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
        return showingPostDetail ||
        showingUserProfile ||
        showingSettings ||
        showingEditProfile ||
        showingCreatePost
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
        if lastNavigation.hasPrefix("postDetail") {
            dismissPostDetail()
        } else if lastNavigation.hasPrefix("userProfile") {
            dismissUserProfile()
        } else if lastNavigation.hasPrefix("settings") {
            dismissSettings()
        } else if lastNavigation.hasPrefix("editProfile") {
            dismissEditProfile()
        } else if lastNavigation.hasPrefix("createPost") {
            dismissCreatePost()
        }
    }
}
