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
        
        // Setup push notifications
        if AppConfig.Features.pushNotificationsEnabled {
            setupPushNotifications(application)
        }
        
        return true
    }
    
    private func setupPushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        Messaging.messaging().delegate = NotificationService.shared
        
        // Request authorization
        Task {
            await NotificationService.shared.requestPermission()
        }
    }
    
    // MARK: - Push Notification Handlers
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.shared.error("Failed to register for remote notifications", error: error, category: "notifications")
    }
}
