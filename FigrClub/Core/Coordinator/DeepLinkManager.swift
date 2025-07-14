//
//  DeepLinkManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import Foundation
import Combine

// MARK: - Deep Link Types
enum DeepLink: Equatable {
    case post(id: String)
    case user(id: String)
    case product(id: String)
    case profile
    case feed
    case marketplace
    case notifications
    case settings
    
    var targetTab: MainTab? {
        switch self {
        case .post, .user, .feed:
            return .feed
        case .product, .marketplace:
            return .marketplace
        case .profile, .settings:
            return .profile
        case .notifications:
            return .notifications
        }
    }
}

// MARK: - Deep Link Manager
@MainActor
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var pendingDeepLink: DeepLink?
    @Published var selectedTab: MainTab = .feed
    
    private var navigationCoordinator: NavigationCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private var isProcessingDeepLink = false
    
    private init() {
        Logger.info("🔗 DeepLinkManager: Initialized")
    }
    
    // MARK: - Setup
    func setup(navigationCoordinator: NavigationCoordinator) {
        self.navigationCoordinator = navigationCoordinator
        Logger.debug("🔗 DeepLinkManager: Connected to NavigationCoordinator")
    }
    
    // MARK: - Handle Deep Links
    func handleURL(_ url: URL) {
        Logger.info("🔗 DeepLinkManager: Handling URL: \(url.absoluteString)")
        
        guard let deepLink = parseURL(url) else {
            Logger.warning("🔗 DeepLinkManager: Unable to parse URL: \(url)")
            return
        }
        
        handleDeepLink(deepLink)
    }
    
    func handleDeepLink(_ deepLink: DeepLink) {
        guard !isProcessingDeepLink else {
            Logger.warning("🔗 DeepLinkManager: Already processing a deep link, ignoring")
            return
        }
        
        Logger.info("🔗 DeepLinkManager: Handling deep link: \(deepLink)")
        isProcessingDeepLink = true
        
        // Cambiar al tab correcto si es necesario
        if let targetTab = deepLink.targetTab {
            selectedTab = targetTab
        }
        
        // Dar tiempo para que el tab se active, luego ejecutar navegación específica
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            await executeDeepLinkNavigation(deepLink)
            isProcessingDeepLink = false
        }
    }
    
    // MARK: - URL Parsing
    private func parseURL(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        let path = components.path
        let queryItems = components.queryItems ?? []
        
        // Parse based on path
        switch path {
        case "/post":
            if let postId = queryItems.first(where: { $0.name == "id" })?.value {
                return .post(id: postId)
            }
            
        case "/user", "/profile":
            if let userId = queryItems.first(where: { $0.name == "id" })?.value {
                return .user(id: userId)
            } else if path == "/profile" {
                return .profile
            }
            
        case "/product", "/marketplace":
            if let productId = queryItems.first(where: { $0.name == "id" })?.value {
                return .product(id: productId)
            } else if path == "/marketplace" {
                return .marketplace
            }
            
        case "/feed":
            return .feed
            
        case "/notifications":
            return .notifications
            
        case "/settings":
            return .settings
            
        default:
            // Try to parse custom scheme URLs
            if url.scheme == "figrclub" {
                return parseCustomScheme(url)
            }
        }
        
        return nil
    }
    
    private func parseCustomScheme(_ url: URL) -> DeepLink? {
        // Handle URLs like: figrclub://post/123, figrclub://profile, etc.
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard !pathComponents.isEmpty else { return .feed }
        
        switch pathComponents[0] {
        case "post":
            if pathComponents.count > 1 {
                return .post(id: pathComponents[1])
            }
        case "user":
            if pathComponents.count > 1 {
                return .user(id: pathComponents[1])
            }
        case "product":
            if pathComponents.count > 1 {
                return .product(id: pathComponents[1])
            }
        case "profile":
            return .profile
        case "feed":
            return .feed
        case "marketplace":
            return .marketplace
        case "notifications":
            return .notifications
        case "settings":
            return .settings
        default:
            break
        }
        
        return nil
    }
    
    // MARK: - Navigation Execution
    private func executeDeepLinkNavigation(_ deepLink: DeepLink) async {
        guard let coordinator = navigationCoordinator else {
            Logger.warning("🔗 DeepLinkManager: NavigationCoordinator not available, storing pending link")
            pendingDeepLink = deepLink
            return
        }
        
        await MainActor.run {
            switch deepLink {
            case .post(let id):
                coordinator.showPostDetail(id)
                
            case .user(let id):
                coordinator.showUserProfile(id)
                
            case .product(let id):
                // Para el futuro cuando implementes marketplace
                Logger.info("🔗 DeepLinkManager: Product deep link: \(id) (feature not implemented)")
                
            case .profile:
                // Ya estamos en el tab de profile, no necesita navegación adicional
                break
                
            case .settings:
                coordinator.showSettings()
                
            case .feed, .marketplace, .notifications:
                // Solo cambio de tab, sin navegación adicional
                break
            }
            
            // Limpiar pending deep link
            pendingDeepLink = nil
        }
    }
    
    // MARK: - Process Pending Deep Links
    func processPendingDeepLinkIfNeeded() {
        guard let pending = pendingDeepLink else { return }
        
        Logger.info("🔗 DeepLinkManager: Processing pending deep link: \(pending)")
        Task {
            await executeDeepLinkNavigation(pending)
        }
    }
    
    // MARK: - Manual Tab Selection
    func selectTab(_ tab: MainTab) {
        guard selectedTab != tab else { return }
        
        Logger.info("🔗 DeepLinkManager: Manual tab selection: \(tab.title)")
        selectedTab = tab
    }
}

// MARK: - Deep Link URL Builder (Utility)
extension DeepLinkManager {
    
    /// Generate shareable URLs for deep linking
    static func buildURL(for deepLink: DeepLink, baseURL: String = "https://figrclub.com") -> URL? {
        var components = URLComponents(string: baseURL)
        
        switch deepLink {
        case .post(let id):
            components?.path = "/post"
            components?.queryItems = [URLQueryItem(name: "id", value: id)]
            
        case .user(let id):
            components?.path = "/user"
            components?.queryItems = [URLQueryItem(name: "id", value: id)]
            
        case .product(let id):
            components?.path = "/product"
            components?.queryItems = [URLQueryItem(name: "id", value: id)]
            
        case .profile:
            components?.path = "/profile"
            
        case .feed:
            components?.path = "/feed"
            
        case .marketplace:
            components?.path = "/marketplace"
            
        case .notifications:
            components?.path = "/notifications"
            
        case .settings:
            components?.path = "/settings"
        }
        
        return components?.url
    }
    
    /// Generate custom scheme URLs
    static func buildCustomURL(for deepLink: DeepLink) -> URL? {
        var components = URLComponents()
        components.scheme = "figrclub"
        
        switch deepLink {
        case .post(let id):
            components.path = "/post/\(id)"
            
        case .user(let id):
            components.path = "/user/\(id)"
            
        case .product(let id):
            components.path = "/product/\(id)"
            
        case .profile:
            components.path = "/profile"
            
        case .feed:
            components.path = "/feed"
            
        case .marketplace:
            components.path = "/marketplace"
            
        case .notifications:
            components.path = "/notifications"
            
        case .settings:
            components.path = "/settings"
        }
        
        return components.url
    }
}

// MARK: - Debug Helpers
#if DEBUG
extension DeepLinkManager {
    
    func testDeepLink(_ deepLink: DeepLink) {
        Logger.debug("🧪 DeepLinkManager: Testing deep link: \(deepLink)")
        handleDeepLink(deepLink)
    }
    
    func printSupportedURLs() {
        let testLinks: [DeepLink] = [
            .post(id: "123"),
            .user(id: "456"),
            .product(id: "789"),
            .profile,
            .feed,
            .marketplace,
            .notifications,
            .settings
        ]
        
        print("🔗 Supported Deep Link URLs:")
        for link in testLinks {
            if let url = Self.buildURL(for: link) {
                print("  • \(url.absoluteString)")
            }
            if let customURL = Self.buildCustomURL(for: link) {
                print("  • \(customURL.absoluteString)")
            }
        }
    }
}
#endif
