//
//  AppCoordinator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import SwiftUI
import Combine

// MARK: - App Level Coordinator
enum AppScreen: Hashable, CaseIterable {
    case splash
    case authentication
    case main
}

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
    
    private let authStateManager: AuthStateManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authStateManager: AuthStateManager) {
        self.authStateManager = authStateManager
        setupBindings()
    }
    
    private func setupBindings() {
        authStateManager.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authState in
                switch authState {
                case .loading:
                    self?.navigate(to: .splash)
                case .authenticated:
                    self?.navigate(to: .main)
                case .unauthenticated, .error:
                    self?.navigate(to: .authentication)
                }
            }
            .store(in: &cancellables)
    }
    
    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: AppConfig.UI.animationDuration)) {
            currentScreen = screen
        }
    }
}

// MARK: - Authentication Coordinator
enum AuthScreen: Hashable {
    case welcome
    case login
    case register
    case forgotPassword
}

@MainActor
class AuthCoordinator: ObservableObject {
    @Published var currentScreen: AuthScreen = .welcome
    @Published var showingLogin = false
    @Published var showingRegister = false
    @Published var showingForgotPassword = false
    
    private let authStateManager: AuthStateManager
    
    init(authStateManager: AuthStateManager) {
        self.authStateManager = authStateManager
    }
    
    func showLogin() {
        showingLogin = true
    }
    
    func showRegister() {
        showingRegister = true
    }
    
    func showForgotPassword() {
        showingForgotPassword = true
    }
    
    func dismissAll() {
        showingLogin = false
        showingRegister = false
        showingForgotPassword = false
    }
    
    func switchToLogin() {
        dismissAll()
        showingLogin = true
    }
    
    func switchToRegister() {
        dismissAll()
        showingRegister = true
    }
}

// MARK: - Main Tab Coordinator
enum MainTab: Int, CaseIterable {
    case feed = 0
    case marketplace = 1
    case create = 2
    case notifications = 3
    case profile = 4
    
    var title: String {
        switch self {
        case .feed: return "Feed"
        case .marketplace: return "Marketplace"
        case .create: return "Crear"
        case .notifications: return "Notificaciones"
        case .profile: return "Perfil"
        }
    }
    
    var icon: String {
        switch self {
        case .feed: return "house"
        case .marketplace: return "cart"
        case .create: return "plus.circle"
        case .notifications: return "bell"
        case .profile: return "person"
        }
    }
}

class MainTabCoordinator: ObservableObject {
    @Published var selectedTab: MainTab = .feed
    
    // Feature coordinators
    let feedCoordinator = FeedCoordinator()
    let marketplaceCoordinator = MarketplaceCoordinator()
    let createCoordinator = CreateCoordinator()
    let notificationsCoordinator = NotificationsCoordinator()
    let profileCoordinator = ProfileCoordinator()
    
    func selectTab(_ tab: MainTab) {
        selectedTab = tab
    }
    
    func resetAllTabs() {
        feedCoordinator.reset()
        marketplaceCoordinator.reset()
        createCoordinator.reset()
        notificationsCoordinator.reset()
        profileCoordinator.reset()
    }
}

// MARK: - Feature Coordinators

// Feed Coordinator
enum FeedScreen: Hashable {
    case feedList
    case postDetail(String) // Post ID
    case userProfile(String) // User ID
    case comments(String) // Post ID
}

class FeedCoordinator: ObservableObject {
    @Published var showingPostDetail = false
    @Published var showingUserProfile = false
    @Published var showingComments = false
    @Published var selectedPostId: String?
    @Published var selectedUserId: String?
    @Published var commentsPostId: String?
    
    func showPostDetail(_ postId: String) {
        selectedPostId = postId
        showingPostDetail = true
    }
    
    func showUserProfile(_ userId: String) {
        selectedUserId = userId
        showingUserProfile = true
    }
    
    func showComments(for postId: String) {
        commentsPostId = postId
        showingComments = true
    }
    
    func reset() {
        showingPostDetail = false
        showingUserProfile = false
        showingComments = false
        selectedPostId = nil
        selectedUserId = nil
        commentsPostId = nil
    }
}

// Marketplace Coordinator
enum MarketplaceScreen: Hashable {
    case productList
    case productDetail(String) // Product ID
    case sellerProfile(String) // Seller ID
    case cart
    case checkout
}

class MarketplaceCoordinator: ObservableObject {
    @Published var showingProductDetail = false
    @Published var showingSellerProfile = false
    @Published var showingCart = false
    @Published var showingCheckout = false
    @Published var selectedProductId: String?
    @Published var selectedSellerId: String?
    
    func showProductDetail(_ productId: String) {
        selectedProductId = productId
        showingProductDetail = true
    }
    
    func showSellerProfile(_ sellerId: String) {
        selectedSellerId = sellerId
        showingSellerProfile = true
    }
    
    func showCart() {
        showingCart = true
    }
    
    func showCheckout() {
        showingCheckout = true
    }
    
    func reset() {
        showingProductDetail = false
        showingSellerProfile = false
        showingCart = false
        showingCheckout = false
        selectedProductId = nil
        selectedSellerId = nil
    }
}

// Create Post Coordinator
enum CreateScreen: Hashable {
    case createOptions
    case createPost
    case createProduct
    case photoCapture
    case photoEditor
}

class CreateCoordinator: ObservableObject {
    @Published var showingCreatePost = false
    @Published var showingCreateProduct = false
    @Published var showingPhotoCapture = false
    @Published var showingPhotoEditor = false
    
    func showCreatePost() {
        showingCreatePost = true
    }
    
    func showCreateProduct() {
        showingCreateProduct = true
    }
    
    func showPhotoCapture() {
        showingPhotoCapture = true
    }
    
    func showPhotoEditor() {
        showingPhotoEditor = true
    }
    
    func reset() {
        showingCreatePost = false
        showingCreateProduct = false
        showingPhotoCapture = false
        showingPhotoEditor = false
    }
}

// Notifications Coordinator
class NotificationsCoordinator: ObservableObject {
    @Published var showingNotificationDetail = false
    @Published var selectedNotificationId: String?
    
    func showNotificationDetail(_ notificationId: String) {
        selectedNotificationId = notificationId
        showingNotificationDetail = true
    }
    
    func reset() {
        showingNotificationDetail = false
        selectedNotificationId = nil
    }
}

// Profile Coordinator
enum ProfileScreen: Hashable {
    case profile
    case editProfile
    case settings
    case myPosts
    case myProducts
    case savedPosts
    case followers
    case following
}

class ProfileCoordinator: ObservableObject {
    @Published var showingEditProfile = false
    @Published var showingSettings = false
    @Published var showingMyPosts = false
    @Published var showingMyProducts = false
    @Published var showingSavedPosts = false
    @Published var showingFollowers = false
    @Published var showingFollowing = false
    
    func showEditProfile() {
        showingEditProfile = true
    }
    
    func showSettings() {
        showingSettings = true
    }
    
    func showMyPosts() {
        showingMyPosts = true
    }
    
    func showMyProducts() {
        showingMyProducts = true
    }
    
    func showSavedPosts() {
        showingSavedPosts = true
    }
    
    func showFollowers() {
        showingFollowers = true
    }
    
    func showFollowing() {
        showingFollowing = true
    }
    
    func reset() {
        showingEditProfile = false
        showingSettings = false
        showingMyPosts = false
        showingMyProducts = false
        showingSavedPosts = false
        showingFollowers = false
        showingFollowing = false
    }
}

// MARK: - Deep Link Manager
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    private init() {}
    
    func handleDeepLink(_ url: URL, coordinator: MainTabCoordinator) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        let path = components.path
        let queryItems = components.queryItems ?? []
        
        switch path {
        case "/post":
            if let postId = queryItems.first(where: { $0.name == "id" })?.value {
                coordinator.selectTab(.feed)
                coordinator.feedCoordinator.showPostDetail(postId)
            }
            
        case "/product":
            if let productId = queryItems.first(where: { $0.name == "id" })?.value {
                coordinator.selectTab(.marketplace)
                coordinator.marketplaceCoordinator.showProductDetail(productId)
            }
            
        case "/user":
            if let userId = queryItems.first(where: { $0.name == "id" })?.value {
                coordinator.selectTab(.feed)
                coordinator.feedCoordinator.showUserProfile(userId)
            }
            
        case "/profile":
            coordinator.selectTab(.profile)
            
        default:
            break
        }
    }
}

// MARK: - Coordinator Factory
class CoordinatorFactory {
    @MainActor
    static func makeAppCoordinator() -> AppCoordinator {
        let authStateManager = DependencyInjector.shared.resolve(AuthStateManager.self)
        return AppCoordinator(authStateManager: authStateManager)
    }
    
    @MainActor
    static func makeAuthCoordinator() -> AuthCoordinator {
        let authStateManager = DependencyInjector.shared.resolve(AuthStateManager.self)
        return AuthCoordinator(authStateManager: authStateManager)
    }
    
    static func makeMainTabCoordinator() -> MainTabCoordinator {
        return MainTabCoordinator()
    }
}
