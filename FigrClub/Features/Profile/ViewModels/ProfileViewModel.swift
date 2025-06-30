//
//  ProfileViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

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
    nonisolated init(apiService: APIServiceProtocol = APIService.shared,
         authManager: AuthManager = DependencyContainer.shared.resolve(AuthManager.self)) {
        self.apiService = apiService
        self.authManager = authManager
    }
    
    // MARK: - Public Methods
    
    func loadUserData() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            userStats = try await apiService
                .request(endpoint: .getUserStats(userId), body: nil)
                .async()
            
        } catch {
            showErrorMessage("Error al cargar datos del perfil: \(error.localizedDescription)")
            Logger.shared.error("Failed to load user data", error: error, category: "profile")
        }
        
        isLoading = false
    }
    
    func loadUserPosts() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        do {
            let response: PaginatedResponse<Post> = try await apiService
                .request(endpoint: .getUserPosts(userId, page: 0, size: 20), body: nil)
                .async()
            
            userPosts = response.content
            
        } catch {
            showErrorMessage("Error al cargar posts: \(error.localizedDescription)")
            Logger.shared.error("Failed to load user posts", error: error, category: "profile")
        }
    }
    
    func shareProfile() {
        guard let user = authManager.currentUser else { return }
        
        let shareText = "¡Echa un vistazo al perfil de \(user.fullName) en FigrClub!"
        let shareURL = URL(string: "https://figrclub.com/profile/\(user.username)")!
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText, shareURL],
            applicationActivities: nil
        )
        
        if let topVC = UIApplication.shared.topViewController {
            topVC.present(activityVC, animated: true)
        }
        
        Analytics.shared.logEvent("profile_shared", parameters: [
            "user_id": user.id
        ])
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.hideError()
        }
    }
    
    private func hideError() {
        errorMessage = nil
        showError = false
    }
}
