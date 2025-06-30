//
//  FigrClubApp.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI

@main
struct FigrClubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = DependencyContainer.shared.resolve(AuthManager.self)
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(notificationService)
                .dependencyInjection()
                .onAppear {
                    setupAppLaunch()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPost)) { notification in
                    handleDeepLink(notification)
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToProfile)) { notification in
                    handleDeepLink(notification)
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToMarketplaceItem)) { notification in
                    handleDeepLink(notification)
                }
        }
    }
    
    private func setupAppLaunch() {
        // Perform initial app setup
        Task {
            // Check authentication status
            if authManager.isAuthenticated {
                _ = await authManager.refreshTokenIfNeeded()
            }
            
            // Request notification permissions if needed
            notificationService.getNotificationSettings()
        }
        
        Logger.shared.info("App launched successfully", category: "app_lifecycle")
    }
    
    private func handleDeepLink(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        Logger.shared.info("Handling deep link: \(notification.name)", category: "deep_link")
        
        // Handle different deep link types
        switch notification.name {
        case .navigateToPost:
            if let postId = userInfo["postId"] as? Int {
                // Navigate to post
                Logger.shared.info("Navigating to post: \(postId)", category: "deep_link")
            }
        case .navigateToProfile:
            if let userId = userInfo["userId"] as? Int {
                // Navigate to profile
                Logger.shared.info("Navigating to profile: \(userId)", category: "deep_link")
            }
        case .navigateToMarketplaceItem:
            if let itemId = userInfo["itemId"] as? Int {
                // Navigate to marketplace item
                Logger.shared.info("Navigating to marketplace item: \(itemId)", category: "deep_link")
            }
        default:
            break
        }
    }
}
