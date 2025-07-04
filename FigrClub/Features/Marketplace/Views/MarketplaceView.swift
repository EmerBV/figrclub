//
//  MarketplaceView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import SwiftUI

// MARK: - Marketplace View
struct MarketplaceView: View {
    var body: some View {}
    
    /*
    @StateObject private var viewModel = DependencyContainer.shared.resolve(MarketplaceViewModel.self)
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $viewModel.searchText, placeholder: "Buscar productos...")
                    .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.small) {
                        ForEach(viewModel.categories) { category in
                            CategoryChip(
                                category: category,
                                isSelected: viewModel.selectedCategory?.id == category.id
                            ) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Items Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.medium) {
                        ForEach(viewModel.items) { item in
                            MarketplaceItemCard(item: item)
                                .onAppear {
                                    if item == viewModel.items.last {
                                        Task {
                                            await viewModel.loadMoreItems()
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    await viewModel.refreshItems()
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Handle create item
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            await viewModel.loadItems()
            await viewModel.loadCategories()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "MarketplaceView")
        }
    }
     */
}
