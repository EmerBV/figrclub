//
//  FigrClubApp.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 17/6/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct FigrClubApp: App {
    @StateObject private var authManager = DependencyInjector.shared.resolve(AuthManager.self)
    
    init() {
        FirebaseApp.configure()
        _ = DependencyInjector.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
