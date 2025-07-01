//
//  MarketplaceViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class MarketplaceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var items: [MarketplaceItem] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var searchText = ""
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
    nonisolated init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
        
        Task { @MainActor in
            setupSearchObserver()
        }
    }
    
    // MARK: - Public Methods
    
    func loadItems() async {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage = 0
        hasMorePages = true
        
        do {
            let response: PaginatedResponse<MarketplaceItem> = try await apiService
                .request(endpoint: .marketplaceItems(page: currentPage, size: pageSize), body: nil)
                .async()
            
            items = response.content
            /*
            currentPage = response.currentPage
            hasMorePages = response.currentPage < response.totalPages - 1
            
            Analytics.shared.logEvent("marketplace_items_loaded", parameters: [
                "items_count": response.content.count,
                "page": currentPage
            ])
             */
            
        } catch {
            showErrorMessage("Error al cargar productos: \(error.localizedDescription)")
            Logger.shared.error("Failed to load marketplace items", error: error, category: "marketplace")
        }
        
        isLoading = false
    }
    
    func loadMoreItems() async {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        
        do {
            let nextPage = currentPage + 1
            let response: PaginatedResponse<MarketplaceItem> = try await apiService
                .request(endpoint: .marketplaceItems(page: nextPage, size: pageSize), body: nil)
                .async()
            
            items.append(contentsOf: response.content)
            /*
            currentPage = response.currentPage
            hasMorePages = response.currentPage < response.totalPages - 1
             */
            
        } catch {
            showErrorMessage("Error al cargar más productos: \(error.localizedDescription)")
        }
        
        isLoadingMore = false
    }
    
    func refreshItems() async {
        currentPage = 0
        hasMorePages = true
        await loadItems()
    }
    
    func loadCategories() async {
        do {
            categories = try await apiService
                .request(endpoint: .getCategories, body: nil)
                .async()
            
        } catch {
            Logger.shared.error("Failed to load categories", error: error, category: "marketplace")
        }
    }
    
    func selectCategory(_ category: Category?) {
        selectedCategory = category
        Task {
            await refreshItems()
        }
        
        Analytics.shared.logEvent("marketplace_category_selected", parameters: [
            "category_id": category?.id ?? -1,
            "category_name": category?.name ?? "all"
        ])
    }
    
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.performSearch(searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ searchText: String) async {
        guard !searchText.isEmpty else {
            await refreshItems()
            return
        }
        
        Analytics.shared.logItemSearch(searchTerm: searchText, category: selectedCategory?.name)
        await refreshItems() // In a real app, this would include search parameters
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
