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
    private let pageSize = 20
    
    // MARK: - Initialization
    nonisolated init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    func loadPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage = 0
        hasMorePages = true
        
        do {
            // FIX: Usar await correctamente con el publisher
            let response: PaginatedResponse<Post> = try await withCheckedThrowingContinuation { continuation in
                apiService.request(endpoint: .publicFeed(page: currentPage, size: pageSize), body: nil)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { (response: PaginatedResponse<Post>) in
                            continuation.resume(returning: response)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            // FIX: Verificar que la respuesta contiene posts
            let newPosts = response.content
            
#if DEBUG
            print("🔍 API Response Debug:")
            print("- Total elements: \(response.totalElements)")
            print("- Current page: \(response.page)")
            print("- Total pages: \(response.totalPages)")
            print("- Posts received: \(newPosts.count)")
            print("- Is last page: \(response.last)")
            print("- Posts IDs: \(newPosts.map { $0.id })")
#endif
            
            // FIX: Asignar los posts y validar datos
            posts = newPosts
            currentPage = response.page
            hasMorePages = !response.last
            
            // FIX: Log detallado para debugging
            Logger.shared.info("✅ Loaded \(newPosts.count) posts from API. Page: \(currentPage), Has more: \(hasMorePages)", category: "feed")
            
            // FIX: Verificar que los posts son únicos
            let uniquePosts = posts.removingDuplicates(by: \.id)
            if uniquePosts.count != posts.count {
                Logger.shared.warning("⚠️ Duplicate posts detected. Before: \(posts.count), After: \(uniquePosts.count)", category: "feed")
                posts = uniquePosts
            }
            
        } catch {
            showErrorMessage("Error al cargar posts: \(error.localizedDescription)")
            Logger.shared.error("❌ Failed to load posts", error: error, category: "feed")
            
#if DEBUG
            print("❌ API Error Details: \(error)")
            if let apiError = error as? APIError {
                print("❌ API Error Type: \(apiError)")
            }
#endif
        }
        
        isLoading = false
    }
    
    func refreshPosts() async {
        currentPage = 0
        hasMorePages = true
        posts.removeAll() // FIX: Limpiar posts antes de recargar
        await loadPosts()
    }
    
    func loadMorePosts() async {
        guard !isLoadingMore && hasMorePages else {
            Logger.shared.info("🛑 Load more blocked: isLoadingMore=\(isLoadingMore), hasMorePages=\(hasMorePages)", category: "feed")
            return
        }
        
        isLoadingMore = true
        
        do {
            let nextPage = currentPage + 1
            
            // FIX: Usar await correctamente con el publisher
            let response: PaginatedResponse<Post> = try await withCheckedThrowingContinuation { continuation in
                apiService.request(endpoint: .publicFeed(page: nextPage, size: pageSize), body: nil)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { (response: PaginatedResponse<Post>) in
                            continuation.resume(returning: response)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            let newPosts = response.content
            
#if DEBUG
            print("🔍 Load More Debug:")
            print("- Page requested: \(nextPage)")
            print("- Posts received: \(newPosts.count)")
            print("- Current posts count: \(posts.count)")
            print("- New posts IDs: \(newPosts.map { $0.id })")
#endif
            
            // FIX: Verificar que no estamos duplicando posts
            let existingIds = Set(posts.map { $0.id })
            let filteredNewPosts = newPosts.filter { !existingIds.contains($0.id) }
            
            if filteredNewPosts.count != newPosts.count {
                Logger.shared.warning("⚠️ Filtered out \(newPosts.count - filteredNewPosts.count) duplicate posts", category: "feed")
            }
            
            posts.append(contentsOf: filteredNewPosts)
            currentPage = response.page
            hasMorePages = !response.last
            
            Logger.shared.info("✅ Loaded \(filteredNewPosts.count) more posts. Total: \(posts.count)", category: "feed")
            
        } catch {
            showErrorMessage("Error al cargar más posts: \(error.localizedDescription)")
            Logger.shared.error("❌ Failed to load more posts", error: error, category: "feed")
        }
        
        isLoadingMore = false
    }
    
    // FIX: Método para debugging manual
    func debugPostsState() {
#if DEBUG
        print("🐛 Posts Debug State:")
        print("- Posts count: \(posts.count)")
        print("- Is loading: \(isLoading)")
        print("- Is loading more: \(isLoadingMore)")
        print("- Current page: \(currentPage)")
        print("- Has more pages: \(hasMorePages)")
        print("- Error message: \(errorMessage ?? "None")")
        print("- Posts IDs: \(posts.map { $0.id })")
        for (index, post) in posts.enumerated() {
            print("  [\(index)] ID: \(post.id), User: \(post.userFullName), Content: \(post.content?.prefix(50) ?? "No content")")
        }
#endif
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

// MARK: - Extensions for Publisher to Async/Await
extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}
