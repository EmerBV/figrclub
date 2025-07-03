//
//  MarketplaceViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class MarketplaceViewModel: SearchableViewModel<MarketplaceItem> {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    
    // MARK: - Use Cases
    private let loadMarketplaceItemsUseCase: LoadMarketplaceItemsUseCase
    private let loadCategoriesUseCase: LoadCategoriesUseCase
    
    // MARK: - Initialization
    init(
        loadMarketplaceItemsUseCase: LoadMarketplaceItemsUseCase,
        loadCategoriesUseCase: LoadCategoriesUseCase
    ) {
        self.loadMarketplaceItemsUseCase = loadMarketplaceItemsUseCase
        self.loadCategoriesUseCase = loadCategoriesUseCase
        super.init()
        
        Task { @MainActor in
            setupCategoryObserver()
        }
    }
    
    // MARK: - Setup
    private func setupCategoryObserver() {
        $selectedCategory
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Override Abstract Methods
    override func loadFirstPage() async {
        await executeWithLoading {
            try await self.loadMarketplaceItemsUseCase.execute(
                LoadMarketplaceItemsInput(
                    page: 0,
                    size: self.pageSize,
                    categoryId: self.selectedCategory?.id,
                    searchQuery: self.searchText.isEmpty ? nil : self.searchText
                )
            )
        } onSuccess: { response in
            self.replaceItems(response.content, from: response)
            Logger.shared.info("Marketplace items loaded: \(response.content.count) items", category: "marketplace")
        }
    }
    
    override func loadNextPage() async {
        await executeWithLoadingMore {
            try await self.loadMarketplaceItemsUseCase.execute(
                LoadMarketplaceItemsInput(
                    page: self.currentPage + 1,
                    size: self.pageSize,
                    categoryId: self.selectedCategory?.id,
                    searchQuery: self.searchText.isEmpty ? nil : self.searchText
                )
            )
        } onSuccess: { response in
            self.appendItems(response.content, from: response)
            Logger.shared.info("More marketplace items loaded: \(response.content.count) items", category: "marketplace")
        }
    }
    
    // MARK: - Public Methods
    func loadCategories() async {
        do {
            categories = try await loadCategoriesUseCase.execute(())
            Logger.shared.info("Categories loaded: \(categories.count)", category: "marketplace")
        } catch {
            Logger.shared.error("Failed to load categories", error: error, category: "marketplace")
        }
    }
    
    func selectCategory(_ category: Category?) {
        selectedCategory = category
    }
    
    func clearCategoryFilter() {
        selectedCategory = nil
    }
}
