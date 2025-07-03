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
final class ProfileViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var userPosts: [Post] = []
    @Published var userStats: UserStats?
    @Published var currentUser: User?
    @Published var showEditProfile = false
    @Published var showSettings = false
    
    // MARK: - Use Cases
    private let loadUserProfileUseCase: LoadUserProfileUseCase
    private let loadUserPostsUseCase: LoadUserPostsUseCase
    private let toggleFollowUserUseCase: ToggleFollowUserUseCase
    private let authManager: AuthManager
    
    // MARK: - Initialization
    nonisolated init(
        loadUserProfileUseCase: LoadUserProfileUseCase,
        loadUserPostsUseCase: LoadUserPostsUseCase,
        toggleFollowUserUseCase: ToggleFollowUserUseCase,
        authManager: AuthManager
    ) {
        self.loadUserProfileUseCase = loadUserProfileUseCase
        self.loadUserPostsUseCase = loadUserPostsUseCase
        self.toggleFollowUserUseCase = toggleFollowUserUseCase
        self.authManager = authManager
        super.init()
        
        Task { @MainActor in
            setupAuthObserver()
        }
    }
    
    // MARK: - Setup
    private func setupAuthObserver() {
        authManager.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                Task { @MainActor in
                    self?.currentUser = user
                    await self?.loadUserData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadUserData() async {
        guard let userId = currentUser?.id else {
            Logger.shared.warning("No current user found", category: "profile")
            return
        }
        
        await executeWithLoading {
            try await self.loadUserProfileUseCase.execute(userId)
        } onSuccess: { (user, stats) in
            self.currentUser = user
            self.userStats = stats
        }
    }
    
    func loadUserPosts() async {
        guard let userId = currentUser?.id else {
            Logger.shared.warning("No current user found for posts", category: "profile")
            return
        }
        
        do {
            let response = try await loadUserPostsUseCase.execute(
                LoadUserPostsInput(userId: userId, page: 0, size: 20)
            )
            userPosts = response.content
            
            Logger.shared.info("User posts loaded: \(response.content.count) posts", category: "profile")
            
        } catch {
            showErrorMessage("Error al cargar posts: \(error.localizedDescription)")
        }
    }
    
    func refreshData() async {
        await loadUserData()
        await loadUserPosts()
    }
    
    func shareProfile() {
        guard let user = currentUser else {
            Logger.shared.warning("No current user to share", category: "profile")
            return
        }
        
        let shareText = "¡Echa un vistazo al perfil de \(user.fullName) en FigrClub!"
        let shareURL = URL(string: "https://figrclub.com/profile/\(user.username)")
        
        var items: [Any] = [shareText]
        if let url = shareURL {
            items.append(url)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        Analytics.shared.logEvent("profile_shared", parameters: [
            "user_id": user.id
        ])
    }
    
    func logout() async {
        await executeWithLoading {
            await self.authManager.logout()
        } onSuccess: { _ in
            Logger.shared.info("User logged out successfully", category: "profile")
        }
    }
}

// MARK: - UserStats Extension for Display
extension UserStats {
    var formattedStats: [(title: String, value: String)] {
        return [
            ("Posts", formatCount(postsCount)),
            ("Seguidores", formatCount(followersCount)),
            ("Siguiendo", formatCount(followingCount)),
            ("Likes", formatCount(likesReceivedCount))
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
