//
//  AppDelegate.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import UIKit
import Firebase
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // Configure Firebase
        FirebaseConfig.shared.configure()
        
        // Configure other services
        configureServices()
        
        // Setup appearance
        setupAppearance()
        
        // Configure analytics
        configureAnalytics()
        
        Logger.shared.info("App did finish launching", category: "app_lifecycle")
        
#if DEBUG
        AppConfig.printDebugInfo()
#endif
        
        return true
    }
    
    // MARK: - Remote Notifications
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.shared.info("Device token received: \(tokenString)", category: "notifications")
        
        // Set FCM token
        Messaging.messaging().apnsToken = deviceToken
        
        Task {
            await NotificationService.shared.registerDeviceToken(tokenString)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.shared.error("Failed to register for remote notifications", error: error, category: "notifications")
    }
    
    // MARK: - Private Methods
    
    private func configureServices() {
        // Configure Core Data
        _ = CoreDataManager.shared
        
        // Configure Notifications
        NotificationService.shared.configure()
        
        // Configure Kingfisher
        KingfisherConfig.shared.configure()
        
        // Configure Crash Reporter
        CrashReporter.shared.configure()
        
        // Validate DI Container
#if DEBUG
        _ = DependencyContainer.shared.validateDependencies()
#endif
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(.figrBackground)
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(.figrTextPrimary)
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(.figrTextPrimary)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(.figrSurface)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure tint color
        UIView.appearance().tintColor = UIColor(.figrPrimary)
    }
    
    private func configureAnalytics() {
        guard AppConfig.FeatureFlags.enableAnalytics else { return }
        
        // Set user properties
        Analytics.shared.setUserProperty(value: AppConfig.AppInfo.version, forName: "app_version")
        Analytics.shared.setUserProperty(value: AppConfig.Environment.current.rawValue, forName: "environment")
        
        // Log app launch
        let launchTime = ProcessInfo.processInfo.systemUptime
        Analytics.shared.logAppLaunch(duration: launchTime)
    }
}
