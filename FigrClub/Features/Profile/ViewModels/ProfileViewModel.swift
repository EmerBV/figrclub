//
//  ProfileViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var userPosts: [Post] = []
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var showEditProfile = false
    @Published var showSettings = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private let apiService: APIServiceProtocol
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    nonisolated init(
        apiService: APIServiceProtocol = APIService.shared,
        authManager: AuthManager = DependencyContainer.shared.resolve(AuthManager.self)
    ) {
        self.apiService = apiService
        self.authManager = authManager
    }
    
    // MARK: - Public Methods
    
    func loadUserData() async {
        guard let userId = authManager.currentUser?.id else {
            Logger.shared.warning("No current user found", category: "profile")
            return
        }
        
        isLoading = true
        
        do {
            let stats: UserStats = try await apiService
                .request(endpoint: .getUserStats(userId), body: nil)
                .async()
            
            userStats = stats
            
            Logger.shared.info("User stats loaded successfully", category: "profile")
            
        } catch {
            showErrorMessage("Error al cargar datos del perfil: \(error.localizedDescription)")
            Logger.shared.error("Failed to load user data", error: error, category: "profile")
        }
        
        isLoading = false
    }
    
    func loadUserPosts() async {
        guard let userId = authManager.currentUser?.id else {
            Logger.shared.warning("No current user found for posts", category: "profile")
            return
        }
        
        do {
            let response: PaginatedResponse<Post> = try await apiService
                .request(endpoint: .getUserPosts(userId, page: 0, size: 20), body: nil)
                .async()
            
            userPosts = response.content
            
            Logger.shared.info("User posts loaded: \(response.content.count) posts", category: "profile")
            
        } catch {
            showErrorMessage("Error al cargar posts: \(error.localizedDescription)")
            Logger.shared.error("Failed to load user posts", error: error, category: "profile")
        }
    }
    
    func refreshData() async {
        await loadUserData()
        await loadUserPosts()
    }
    
    func shareProfile() {
        guard let user = authManager.currentUser else {
            Logger.shared.warning("No current user to share", category: "profile")
            return
        }
        
        let shareText = "¡Echa un vistazo al perfil de \(user.fullName) en FigrClub!"
        let shareURL = URL(string: "https://figrclub.com/profile/\(user.username)")!
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText, shareURL],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.topViewController?.view
            popover.sourceRect = CGRect(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        // Present activity controller
        if let topVC = UIApplication.shared.topViewController {
            topVC.present(activityVC, animated: true)
            
            Analytics.shared.logEvent("profile_shared", parameters: [
                "user_id": user.id,
                "username": user.username
            ])
        } else {
            Logger.shared.warning("No top view controller found for sharing", category: "profile")
        }
    }
    
    // MARK: - Private Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                hideError()
            }
        }
    }
    
    private func hideError() {
        errorMessage = nil
        showError = false
    }
}

// MARK: - UserStats Extension for Display
extension UserStats {
    var formattedStats: [(title: String, value: String)] {
        return [
            ("Posts", formatCount(postsCount)),
            ("Seguidores", formatCount(followersCount)),
            ("Siguiendo", formatCount(followingCount)),
            ("Likes", formatCount(likesReceived))
        ]
    }
    
    private func formatCount(_ count: Int) -> String {
        switch count {
        case 0..<1000:
            return "\(count)"
        case 1000..<1_000_000:
            let formatted = Double(count) / 1000.0
            return String(format: "%.1fK", formatted)
        default:
            let formatted = Double(count) / 1_000_000.0
            return String(format: "%.1fM", formatted)
        }
    }
}
