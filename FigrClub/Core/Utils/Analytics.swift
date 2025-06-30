//
//  Analytics.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

// MARK: - Analytics
final class Analytics {
    static let shared = Analytics()
    
    private init() {}
    
    // MARK: - User Events
    func logLogin(method: String) {
        logEvent("login", parameters: [
            "method": method
        ])
    }
    
    func logSignup(method: String) {
        logEvent("sign_up", parameters: [
            "method": method
        ])
    }
    
    func logLogout() {
        logEvent("logout")
    }
    
    // MARK: - Navigation Events
    func logScreenView(screenName: String, screenClass: String? = nil) {
        logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }
    
    // MARK: - Social Events
    func logPostCreated(postType: String) {
        logEvent("post_created", parameters: [
            "post_type": postType
        ])
    }
    
    func logPostLike(postId: String) {
        logEvent("post_like", parameters: [
            "post_id": postId
        ])
    }
    
    func logPostShare(postId: String, method: String) {
        logEvent("post_share", parameters: [
            "post_id": postId,
            "method": method
        ])
    }
    
    func logFollowUser(userId: String) {
        logEvent("follow_user", parameters: [
            "followed_user_id": userId
        ])
    }
    
    // MARK: - Marketplace Events
    func logItemView(itemId: String, category: String) {
        logEvent("view_item", parameters: [
            "item_id": itemId,
            "item_category": category
        ])
    }
    
    func logItemFavorite(itemId: String) {
        logEvent("item_favorite", parameters: [
            "item_id": itemId
        ])
    }
    
    func logItemSearch(searchTerm: String, category: String? = nil) {
        var parameters: [String: Any] = [
            "search_term": searchTerm
        ]
        
        if let category = category {
            parameters["search_category"] = category
        }
        
        logEvent(AnalyticsEventSearch, parameters: parameters)
    }
    
    func logItemPurchase(itemId: String, price: Double, currency: String) {
        logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: itemId,
            AnalyticsParameterValue: price,
            AnalyticsParameterCurrency: currency
        ])
    }
    
    // MARK: - Chat Events
    func logMessageSent(conversationId: String) {
        logEvent("message_sent", parameters: [
            "conversation_id": conversationId
        ])
    }
    
    func logConversationStarted(withUserId: String) {
        logEvent("conversation_started", parameters: [
            "with_user_id": withUserId
        ])
    }
    
    // MARK: - Error Events
    func logError(error: Error, context: String) {
        logEvent("error_occurred", parameters: [
            "error_message": error.localizedDescription,
            "context": context
        ])
    }
    
    func logAPIError(endpoint: String, statusCode: Int?, errorMessage: String) {
        logEvent("api_error", parameters: [
            "endpoint": endpoint,
            "status_code": statusCode ?? -1,
            "error_message": errorMessage
        ])
    }
    
    // MARK: - Performance Events
    func logPerformance(operation: String, duration: TimeInterval) {
        logEvent("performance", parameters: [
            "operation": operation,
            "duration_ms": Int(duration * 1000)
        ])
    }
    
    func logAppLaunch(duration: TimeInterval) {
        logEvent("app_launch", parameters: [
            "duration_ms": Int(duration * 1000)
        ])
    }
    
    // MARK: - User Properties
    func setUserProperty(value: String?, forName: String) {
        guard AppConfig.FeatureFlags.enableAnalytics else { return }
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: forName)
    }
    
    func setUserId(_ userId: String?) {
        guard AppConfig.FeatureFlags.enableAnalytics else { return }
        FirebaseAnalytics.Analytics.setUserID(userId)
    }
    
    func setUserType(_ userType: String) {
        setUserProperty(value: userType, forName: "user_type")
    }
    
    func setSubscriptionType(_ subscriptionType: String) {
        setUserProperty(value: subscriptionType, forName: "subscription_type")
    }
    
    // MARK: - Private Methods
    private func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard AppConfig.FeatureFlags.enableAnalytics else { return }
        
        Logger.shared.debug("Analytics event: \(name) with parameters: \(parameters ?? [:])", category: "analytics")
        
        FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters)
    }
}

extension Analytics {
    
    struct Categories {
        static let authentication = "authentication"
        static let social = "social"
        static let marketplace = "marketplace"
        static let chat = "chat"
        static let navigation = "navigation"
        static let performance = "performance"
        static let error = "error"
        static let user = "user"
    }
    
    struct Events {
        // Authentication
        static let login = "login"
        static let signUp = "sign_up"
        static let logout = "logout"
        static let passwordReset = "password_reset"
        static let emailVerification = "email_verification"
        
        // Social
        static let postCreated = "post_created"
        static let postLiked = "post_liked"
        static let postShared = "post_shared"
        static let postCommented = "post_commented"
        static let userFollowed = "user_followed"
        static let userUnfollowed = "user_unfollowed"
        
        // Marketplace
        static let itemViewed = "item_viewed"
        static let itemFavorited = "item_favorited"
        static let itemUnfavorited = "item_unfavorited"
        static let itemPurchased = "item_purchased"
        static let itemListed = "item_listed"
        static let searchPerformed = "search_performed"
        
        // Chat
        static let messageSent = "message_sent"
        static let conversationStarted = "conversation_started"
        static let conversationEnded = "conversation_ended"
        
        // Navigation
        static let screenViewed = "screen_viewed"
        static let tabChanged = "tab_changed"
        static let deepLinkOpened = "deep_link_opened"
        
        // Performance
        static let appLaunched = "app_launched"
        static let apiCallMade = "api_call_made"
        static let imageLoaded = "image_loaded"
        
        // Errors
        static let errorOccurred = "error_occurred"
        static let crashOccurred = "crash_occurred"
    }
    
    struct Parameters {
        // Common
        static let itemId = "item_id"
        static let userId = "user_id"
        static let postId = "post_id"
        static let category = "category"
        static let source = "source"
        static let method = "method"
        static let duration = "duration"
        static let success = "success"
        
        // Search
        static let searchTerm = "search_term"
        static let searchFilters = "search_filters"
        static let resultsCount = "results_count"
        
        // Commerce
        static let price = "price"
        static let currency = "currency"
        static let quantity = "quantity"
        
        // Error
        static let errorMessage = "error_message"
        static let errorCode = "error_code"
        static let stackTrace = "stack_trace"
    }
    
}
