//
//  FeedViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 0
    private var hasMorePages = true
    private let pageSize = AppConfig.Pagination.defaultPageSize
    
    // MARK: - Initialization
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    func loadPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage = 0
        hasMorePages = true
        
        do {
            let response: PaginatedResponse<Post> = try await apiService
                .request(endpoint: .publicFeed(page: currentPage, size: pageSize), body: nil)
                .async()
            
            posts = response.content
            currentPage = response.currentPage
            hasMorePages = response.currentPage < response.totalPages - 1
            
            Logger.shared.info("Loaded \(response.content.count) posts", category: "feed")
            
        } catch {
            showErrorMessage("Error al cargar posts: \(error.localizedDescription)")
            Logger.shared.error("Failed to load posts", error: error, category: "feed")
        }
        
        isLoading = false
    }
    
    func refreshPosts() async {
        currentPage = 0
        hasMorePages = true
        await loadPosts()
    }
    
    func loadMorePosts() async {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        
        do {
            let nextPage = currentPage + 1
            let response: PaginatedResponse<Post> = try await apiService
                .request(endpoint: .publicFeed(page: nextPage, size: pageSize), body: nil)
                .async()
            
            posts.append(contentsOf: response.content)
            currentPage = response.currentPage
            hasMorePages = response.currentPage < response.totalPages - 1
            
            Logger.shared.info("Loaded \(response.content.count) more posts", category: "feed")
            
        } catch {
            showErrorMessage("Error al cargar más posts: \(error.localizedDescription)")
            Logger.shared.error("Failed to load more posts", error: error, category: "feed")
        }
        
        isLoadingMore = false
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
