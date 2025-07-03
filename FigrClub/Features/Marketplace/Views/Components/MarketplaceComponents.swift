//
//  MarketplaceComponents.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import SwiftUI
import Kingfisher

// MARK: - Marketplace Item Card
struct MarketplaceItemCard: View {
    let item: MarketplaceItem
    @State private var isFavorited: Bool
    
    init(item: MarketplaceItem) {
        self.item = item
        self._isFavorited = State(initialValue: item.isFavoritedByCurrentUser ?? false)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let firstImage = item.images.first {
                    KFImage(URL(string: firstImage))
                        .placeholder {
                            Rectangle()
                                .fill(.figrBorder)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.figrTextSecondary)
                                )
                        }
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(.figrBorder)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.figrTextSecondary)
                        )
                }
                
                // Favorite Button
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.figrBody)
                        .foregroundColor(isFavorited ? .figrError : .white)
                        .padding(Spacing.small)
                        .background(.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(Spacing.small)
            }
            .cornerRadius(CornerRadius.medium)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(item.title)
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                    .lineLimit(2)
                
                Text("\(item.price, specifier: "%.2f") \(item.currency)")
                    .font(.figrHeadline)
                    .foregroundColor(.figrPrimary)
                
                HStack {
                    Text(item.condition.displayName)
                        .font(.figrCaption)
                        .foregroundColor(.figrTextSecondary)
                    
                    Spacer()
                    
                    if item.status != .available {
                        FigrBadge(text: item.status.displayName, style: .secondary)
                    }
                }
            }
            .padding(.horizontal, Spacing.xSmall)
        }
        .background(.figrSurface)
        .cornerRadius(CornerRadius.medium)
        .defaultShadow()
        .onTapGesture {
            Analytics.shared.logItemView(itemId: String(item.id), category: item.category.name)
        }
    }
    
    private func toggleFavorite() {
        isFavorited.toggle()
        HapticManager.shared.impact(.light)
        
        Task.detached(priority: .userInitiated) {
            do {
                if isFavorited {
                    let _: EmptyResponse = try await APIService.shared
                        .request(endpoint: .addToFavorites(item.id), body: nil)
                        .async()
                    
                    Analytics.shared.logItemFavorite(itemId: String(item.id))
                } else {
                    let _: EmptyResponse = try await APIService.shared
                        .request(endpoint: .removeFromFavorites(item.id), body: nil)
                        .async()
                }
            } catch {
                // Revert optimistic update
                await MainActor.run {
                    isFavorited.toggle()
                }
                Logger.shared.error("Failed to toggle favorite", error: error, category: "marketplace")
            }
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.figrCallout)
                .foregroundColor(isSelected ? .white : .figrTextPrimary)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(isSelected ? .figrPrimary : .figrSurface)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(isSelected ? .clear : .figrBorder, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

