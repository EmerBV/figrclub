//
//  Analytics.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import FirebaseAnalytics

final class Analytics {
    static let shared = Analytics()
    
    private var isConfigured = false
    private var userId: String?
    
    private init() {}
    
    // MARK: - Configuration
    func configure() {
        isConfigured = true
        Logger.shared.info("Analytics configured", category: "analytics")
    }
    
    // MARK: - User Properties
    func setUserId(_ userId: String?) {
        guard isConfigured else { return }
        self.userId = userId
        FirebaseAnalytics.Analytics.setUserID(userId)
        Logger.shared.info("Analytics user ID set: \(userId ?? "nil")", category: "analytics")
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        guard isConfigured else { return }
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: name)
    }
    
    func setUserType(_ userType: String) {
        setUserProperty(userType, forName: "user_type")
    }
    
    // MARK: - Events
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isConfigured else { return }
        
        FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters)
        
#if DEBUG
        var debugMessage = "Analytics event: \(name)"
        if let parameters = parameters {
            debugMessage += " - Parameters: \(parameters)"
        }
        Logger.shared.debug(debugMessage, category: "analytics")
#endif
    }
    
    // MARK: - Screen Tracking
    func logScreenView(screenName: String, screenClass: String? = nil) {
        logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }
    
    // MARK: - Authentication Events
    func logLogin(method: String) {
        logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    func logSignup(method: String) {
        logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    func logLogout() {
        logEvent("logout")
    }
    
    // MARK: - Commerce Events
    func logPurchase(value: Double, currency: String, transactionId: String) {
        logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterValue: value,
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterTransactionID: transactionId
        ])
    }
    
    func logAddToCart(itemId: String, itemName: String, value: Double) {
        logEvent(AnalyticsEventAddToCart, parameters: [
            AnalyticsParameterItemID: itemId,
            AnalyticsParameterItemName: itemName,
            AnalyticsParameterValue: value
        ])
    }
    
    // MARK: - Content Events
    func logShare(contentType: String, itemId: String) {
        logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterContentType: contentType,
            AnalyticsParameterItemID: itemId
        ])
    }
    
    func logSelectContent(contentType: String, itemId: String) {
        logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterContentType: contentType,
            AnalyticsParameterItemID: itemId
        ])
    }
    
    // MARK: - Error Events
    func logError(_ error: Error, context: String? = nil) {
        var parameters: [String: Any] = [
            "error_description": error.localizedDescription
        ]
        
        if let context = context {
            parameters["context"] = context
        }
        
        logEvent("error_occurred", parameters: parameters)
    }
    
    // MARK: - App Lifecycle
    func pause() {
        // Pausar analytics si es necesario
    }
    
    func resume() {
        // Reanudar analytics si es necesario
    }
}

extension Analytics {
    
    // MARK: - Social Events
    func logPostLike(postId: String) {
        logEvent("post_like", parameters: [
            "post_id": postId
        ])
    }
    
    func logPostUnlike(postId: String) {
        logEvent("post_unlike", parameters: [
            "post_id": postId
        ])
    }
    
    func logPostShare(postId: String, method: String) {
        logEvent("post_share", parameters: [
            "post_id": postId,
            "method": method
        ])
    }
    
    func logPostComment(postId: String) {
        logEvent("post_comment", parameters: [
            "post_id": postId
        ])
    }
    
    // MARK: - User Events
    func logUserFollow(targetUserId: String) {
        logEvent("user_follow", parameters: [
            "target_user_id": targetUserId
        ])
    }
    
    func logUserUnfollow(targetUserId: String) {
        logEvent("user_unfollow", parameters: [
            "target_user_id": targetUserId
        ])
    }
    
    // MARK: - Marketplace Events
    func logItemView(itemId: String, categoryId: String? = nil) {
        var parameters: [String: Any] = [
            "item_id": itemId
        ]
        
        if let categoryId = categoryId {
            parameters["category_id"] = categoryId
        }
        
        logEvent("item_view", parameters: parameters)
    }
    
    func logItemFavorite(itemId: String) {
        logEvent("item_favorite", parameters: [
            "item_id": itemId
        ])
    }
    
    func logItemSearch(query: String, resultsCount: Int) {
        logEvent("item_search", parameters: [
            "search_query": query,
            "results_count": resultsCount
        ])
    }
}
