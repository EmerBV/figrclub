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
    @Published var showingPostDetail = false
    @Published var showingUserProfile = false
    @Published var showingUserProfileDetail = false
    @Published var showingSettings = false
    @Published var showingEditProfile = false
    @Published var showingCreatePost = false
    
    // IDs para navegación
    @Published var selectedPostId: String?
    @Published var selectedUserId: String?
    @Published var selectedUserForDetail: User?
    
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
    
    func dismissAll() {
        Logger.info("🧭 NavigationCoordinator: Dismissing all presentations")
        
        showingPostDetail = false
        showingUserProfile = false
        showingUserProfileDetail = false
        showingSettings = false
        showingEditProfile = false
        showingCreatePost = false
        
        selectedPostId = nil
        selectedUserId = nil
        selectedUserForDetail = nil
        
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
        showingUserProfileDetail ||
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
        } else if lastNavigation.hasPrefix("userProfileDetail") {
            dismissUserProfileDetail()
            
        } else if lastNavigation.hasPrefix("settings") {
            dismissSettings()
        } else if lastNavigation.hasPrefix("editProfile") {
            dismissEditProfile()
        } else if lastNavigation.hasPrefix("createPost") {
            dismissCreatePost()
        }
    }
}

// MARK: - Create Flow Navigation Extension
/*
 extension NavigationCoordinator {
 
 /// Presenta el flujo de creación de contenido
 /// - Parameter user: Usuario actual
 func presentCreateFlow(for user: User) {
 Logger.info("Presenting create flow for user: \(user.username)")
 
 // Aquí implementarías la lógica para presentar el CreateFlowView
 // Esto dependerá de cómo manejes la navegación en tu app
 
 // Ejemplo de implementación:
 // presentSheet(.createFlow(user))
 }
 
 /// Cierra el flujo de creación
 func dismissCreateFlow() {
 Logger.info("Dismissing create flow")
 
 // Aquí implementarías la lógica para cerrar el CreateFlowView
 // Ejemplo:
 // dismissSheet()
 }
 
 /// Navega a la pantalla de edición de media
 /// - Parameters:
 ///   - image: Imagen capturada (opcional)
 ///   - videoURL: URL del video capturado (opcional)
 ///   - user: Usuario actual
 func navigateToMediaEdit(image: UIImage? = nil, videoURL: URL? = nil, for user: User) {
 Logger.info("Navigating to media edit")
 
 // Implementar navegación a pantalla de edición
 // Ejemplo:
 // push(.mediaEdit(image: image, videoURL: videoURL, user: user))
 }
 
 /// Navega a la pantalla de configuración de cámara
 func navigateToCameraSettings() {
 Logger.info("Navigating to camera settings")
 
 // Implementar navegación a configuración de cámara
 // Ejemplo:
 // presentSheet(.cameraSettings)
 }
 }
 
 // MARK: - Create Flow Sheet Types (si usas enum para sheets)
 extension NavigationCoordinator {
 
 /// Tipos de sheets específicos para el create flow
 enum CreateFlowSheet: Identifiable {
 case createFlow(User)
 case mediaEdit(image: UIImage?, videoURL: URL?, user: User)
 case cameraSettings
 case imageLibrary
 case musicSelection
 case effectsLibrary
 
 var id: String {
 switch self {
 case .createFlow:
 return "createFlow"
 case .mediaEdit:
 return "mediaEdit"
 case .cameraSettings:
 return "cameraSettings"
 case .imageLibrary:
 return "imageLibrary"
 case .musicSelection:
 return "musicSelection"
 case .effectsLibrary:
 return "effectsLibrary"
 }
 }
 }
 }
 
 // MARK: - Create Flow Routing (si usas enum para rutas)
 extension NavigationCoordinator {
 
 /// Rutas específicas del create flow
 enum CreateFlowRoute: Hashable {
 case camera
 case mediaEdit(image: UIImage?, videoURL: URL?)
 case postCompose(media: MediaAsset)
 case storyEdit(media: MediaAsset)
 case reelEdit(media: MediaAsset)
 case liveStreamSetup
 
 // Implementar Hashable
 func hash(into hasher: inout Hasher) {
 switch self {
 case .camera:
 hasher.combine("camera")
 case .mediaEdit:
 hasher.combine("mediaEdit")
 case .postCompose:
 hasher.combine("postCompose")
 case .storyEdit:
 hasher.combine("storyEdit")
 case .reelEdit:
 hasher.combine("reelEdit")
 case .liveStreamSetup:
 hasher.combine("liveStreamSetup")
 }
 }
 
 static func == (lhs: CreateFlowRoute, rhs: CreateFlowRoute) -> Bool {
 switch (lhs, rhs) {
 case (.camera, .camera),
 (.mediaEdit, .mediaEdit),
 (.postCompose, .postCompose),
 (.storyEdit, .storyEdit),
 (.reelEdit, .reelEdit),
 (.liveStreamSetup, .liveStreamSetup):
 return true
 default:
 return false
 }
 }
 }
 }
 */

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
