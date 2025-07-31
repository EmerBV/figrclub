//
//  MarketplaceFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI
import Kingfisher

struct MarketplaceFlowView: View {
    let user: User
    @Environment(\.localizationManager) private var localizationManager
    
    // MARK: - Environment Objects
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Estado local
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory = .all
    @State private var showFilters = false
    @State private var products: [MarketplaceProduct] = sampleProducts
    @State private var featuredProducts: [MarketplaceProduct] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                headerSection
                categoriesSection
                productsSection
            }
            .themedBackground()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showFilters) {
            FiltersSheet(selectedCategory: $selectedCategory)
        }
        .onAppear {
            setupFeaturedProducts()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            HStack {
                Text("Marketplace")
                    .themedFont(.displayMedium)
                    .themedTextColor(.primary)
                
                Spacer()
                
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .themedTextColor(.primary)
                }
            }
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .themedTextColor(.secondary)
                
                TextField(localizationManager.localizedString(for: .searchTextfield), text: $searchText)
                    .themedFont(.bodyMedium)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .themedTextColor(.secondary)
                    }
                }
            }
            .padding(AppTheme.Spacing.large)
            .background(Color(.systemGray6))
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.large)

    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ProductCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
            }
            .padding(.vertical, AppTheme.Spacing.small)
            
            Divider()
                .background(themeManager.currentSecondaryTextColor.opacity(0.3))
        }
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                featuredProductsView
                productsGridView
            }
        }
        .refreshable {
            await refreshMarketplace()
        }
    }
    
    // MARK: - Featured Products View
    private var featuredProductsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localizationManager.localizedString(for: .featuredString))
                    .themedFont(.headlineMedium)
                    .themedTextColor(.primary)
                
                Spacer()
                
                Button(localizationManager.localizedString(for: .seeAllString)) {
                    // TODO: Navegar a destacados
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(featuredProducts.prefix(5)) { product in
                        FeaturedProductCard(product: product) {
                            // TODO: Navegar a detalle del producto
                            Logger.info("🛍️ Featured product tapped: \(product.title)")
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
            }
        }
    }
    
    // MARK: - Products Grid View
    private var productsGridView: some View {
        LazyVStack(spacing: 0) {
            // Header de sección
            HStack {
                Text(localizationManager.localizedString(for: .allProductsString))
                    .themedFont(.headlineMedium)
                    .themedTextColor(.primary)
                
                Spacer()
                
                Text(localizationManager.localizedString(for: .numberOfProducts, arguments: filteredProducts.count))
                    .font(.system(size: 14))
                    .themedTextColor(.secondary)
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, 12)
            
            // Grid de productos
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                spacing: AppTheme.Spacing.large
            ) {
                ForEach(filteredProducts) { product in
                    ProductCard(product: product) {
                        // TODO: Navegar a detalle del producto
                        Logger.info("🛍️ Product tapped: \(product.title)")
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .padding(.bottom, AppTheme.Spacing.large)
    }
    
    // MARK: - Computed Properties
    private var filteredProducts: [MarketplaceProduct] {
        products.filter { product in
            let matchesSearch = searchText.isEmpty ||
            product.title.localizedCaseInsensitiveContains(searchText) ||
            product.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == .all || product.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
    
    // MARK: - Private Methods
    private func setupFeaturedProducts() {
        featuredProducts = products.filter(\.isFeatured)
    }
    
    private func refreshMarketplace() async {
        Logger.info("🔄 MarketplaceFlowView: Refreshing marketplace")
        
        // Simular carga desde servidor
        try? await Task.sleep(for: .seconds(1))
        
        // Aquí se cargarían los productos reales desde el servidor
        Logger.info("✅ MarketplaceFlowView: Marketplace refreshed")
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: ProductCategory
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        Button(action: action) {
            Text(localizationManager.localizedString(for: category.localizedStringKey))
                .themedFont(.titleSmall)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Featured Product Card
struct FeaturedProductCard: View {
    let product: MarketplaceProduct
    let action: () -> Void
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Imagen del producto
                ZStack(alignment: .topTrailing) {
                    KFImage(URL(string: product.imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 160)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Badge de destacado
                    Text("⭐")
                        .font(.system(size: 12))
                        .figrSpacing(.xSmall)
                        .background(Color.yellow)
                        .cornerRadius(6)
                        .offset(x: -6, y: 6)
                }
                
                // Información del producto
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text(product.title)
                        .font(.system(size: 14, weight: .semibold))
                        .themedTextColor(.primary)
                        .lineLimit(2)
                        .frame(height: 34, alignment: .top)
                        .multilineTextAlignment(.leading)
                    
                    Text(localizationManager.currencyString(from: product.price))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 4) {
                        KFImage(URL(string: product.sellerProfileImage))
                            .profileImageStyle(size: 16)
                        
                        Text(product.sellerName)
                            .themedFont(.bodyXSmall)
                            .themedTextColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .figrSpacing(.xSmall)
                .frame(width: 160, alignment: .leading)
            }
            .frame(width: 160)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: MarketplaceProduct
    let action: () -> Void
    
    @State private var isFavorite = false
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Imagen del producto
                ZStack(alignment: .topTrailing) {
                    KFImage(URL(string: product.imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Botón de favorito
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFavorite.toggle()
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(isFavorite ? .red : .white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    .offset(x: -8, y: 8)
                }
                
                // Información del producto
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text(product.title)
                        .font(.system(size: 14, weight: .semibold))
                        .themedTextColor(.primary)
                        .lineLimit(2)
                        .frame(height: 34, alignment: .top)
                        .multilineTextAlignment(.leading)
                    
                    Text(localizationManager.currencyString(from: product.price))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    // Condición del producto
                    Text(product.condition.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(product.condition.color)
                        )
                    
                    HStack(spacing: 4) {
                        KFImage(URL(string: product.sellerProfileImage))
                            .profileImageStyle(size: 16)
                        
                        Text(product.sellerName)
                            .themedFont(.bodyXSmall)
                            .themedTextColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let location = product.location {
                            HStack(spacing: 2) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                    .themedTextColor(.secondary)
                                
                                Text(location)
                                    .font(.system(size: 10))
                                    .themedTextColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        //.themedCard()
        /*
         .background(
         RoundedRectangle(cornerRadius: 12)
         .fill(Color(.systemBackground))
         .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
         )
         */
    }
}

// MARK: - Filters Sheet
struct FiltersSheet: View {
    @Binding var selectedCategory: ProductCategory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.screenPadding) {
                // Categorías
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localizedString(for: .categoryString))
                        .themedFont(.titleLarge)
                        .themedTextColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppTheme.Spacing.small) {
                        ForEach(ProductCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(localizationManager.localizedString(for: category.localizedStringKey))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .padding(.horizontal, AppTheme.Spacing.medium)
                                    .padding(.vertical, AppTheme.Spacing.small)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedCategory == category ? Color.blue : Color(.systemGray6))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
                
                // Botones de acción
                VStack(spacing: AppTheme.Spacing.medium) {
                    Button(localizationManager.localizedString(for: .applyFilterString)) {
                        dismiss()
                    }
                    .buttonStyle(EBVPrimaryBtnStyle())
                    
                    Button(localizationManager.localizedString(for: .clearFilterString)) {
                        selectedCategory = .all
                    }
                    .themedFont(.titleMedium)
                    .foregroundColor(.blue)
                }
            }
            .padding(20)
            .navigationTitle(localizationManager.localizedString(for: .filtersString))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: .close)) {
                        dismiss()
                    }
                }
            }
            .themedBackground()
        }
    }
}

// MARK: - Data Models
struct MarketplaceProduct: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let price: Double
    let imageURL: String
    let sellerName: String
    let sellerProfileImage: String
    let category: ProductCategory
    let condition: ProductCondition
    let location: String?
    let isFeatured: Bool
    let createdAt: Date
}

enum ProductCategory: CaseIterable {
    case all
    case anime
    case manga
    case gaming
    case movies
    case tv
    case collectibles
    case vintage
    
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .all: return .categoryAll
        case .anime: return .categoryAnime
        case .manga: return .categoryManga
        case .gaming: return .categoryGaming
        case .movies: return .categoryMovies
        case .tv: return .categoryTv
        case .collectibles: return .categoryCollectibles
        case .vintage: return .categoryVintage
        }
    }
}

enum ProductCondition: CaseIterable {
    case new
    case likeNew
    case good
    case fair
    case poor
    
    var displayName: String {
        switch self {
        case .new: return "Nuevo"
        case .likeNew: return "Como nuevo"
        case .good: return "Bueno"
        case .fair: return "Regular"
        case .poor: return "Pobre"
        }
    }
    
    var color: Color {
        switch self {
        case .new: return .green
        case .likeNew: return .blue
        case .good: return .orange
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

// MARK: - Sample Data
extension MarketplaceFlowView {
    static let sampleProducts: [MarketplaceProduct] = [
        MarketplaceProduct(
            title: "Figura Goku Ultra Instinct",
            description: "Figura de Dragon Ball Super en perfectas condiciones",
            price: 89.99,
            imageURL: "https://picsum.photos/seed/goku/400/400",
            sellerName: "ana_figuras",
            sellerProfileImage: "https://picsum.photos/seed/seller1/100/100",
            category: .anime,
            condition: .new,
            location: "Madrid",
            isFeatured: true,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        MarketplaceProduct(
            title: "Colección Naruto Shippuden",
            description: "Set completo de figuras de Naruto, Sasuke y Sakura",
            price: 159.99,
            imageURL: "https://picsum.photos/seed/naruto/400/400",
            sellerName: "carlos_otaku",
            sellerProfileImage: "https://picsum.photos/seed/seller2/100/100",
            category: .anime,
            condition: .likeNew,
            location: "Barcelona",
            isFeatured: true,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        MarketplaceProduct(
            title: "Zelda Breath of the Wild",
            description: "Figura de Link con accesorios incluidos",
            price: 75.50,
            imageURL: "https://picsum.photos/seed/zelda/400/400",
            sellerName: "gaming_pro",
            sellerProfileImage: "https://picsum.photos/seed/seller3/100/100",
            category: .gaming,
            condition: .good,
            location: "Valencia",
            isFeatured: false,
            createdAt: Date().addingTimeInterval(-10800)
        ),
        MarketplaceProduct(
            title: "Iron Man Mark 85",
            description: "Figura de alta calidad de Avengers Endgame",
            price: 199.99,
            imageURL: "https://picsum.photos/seed/ironman/400/400",
            sellerName: "marvel_fan",
            sellerProfileImage: "https://picsum.photos/seed/seller4/100/100",
            category: .movies,
            condition: .new,
            location: "Sevilla",
            isFeatured: true,
            createdAt: Date().addingTimeInterval(-14400)
        ),
        MarketplaceProduct(
            title: "Pokemon Pikachu Vintage",
            description: "Figura clásica de Pikachu de los 90s",
            price: 45.00,
            imageURL: "https://picsum.photos/seed/pikachu/400/400",
            sellerName: "retro_collector",
            sellerProfileImage: "https://picsum.photos/seed/seller5/100/100",
            category: .vintage,
            condition: .fair,
            location: "Bilbao",
            isFeatured: false,
            createdAt: Date().addingTimeInterval(-18000)
        ),
        MarketplaceProduct(
            title: "One Piece Luffy Gear 4",
            description: "Figura de Monkey D. Luffy en su forma Gear Fourth",
            price: 95.00,
            imageURL: "https://picsum.photos/seed/luffy/400/400",
            sellerName: "onepiece_lover",
            sellerProfileImage: "https://picsum.photos/seed/seller6/100/100",
            category: .anime,
            condition: .likeNew,
            location: "Zaragoza",
            isFeatured: true,
            createdAt: Date().addingTimeInterval(-21600)
        ),
        MarketplaceProduct(
            title: "Demon Slayer Tanjiro",
            description: "Figura de Tanjiro Kamado con efectos de agua",
            price: 67.99,
            imageURL: "https://picsum.photos/seed/tanjiro/400/400",
            sellerName: "demon_slayer_fan",
            sellerProfileImage: "https://picsum.photos/seed/seller7/100/100",
            category: .anime,
            condition: .new,
            location: "Málaga",
            isFeatured: false,
            createdAt: Date().addingTimeInterval(-25200)
        ),
        MarketplaceProduct(
            title: "Batman Dark Knight",
            description: "Figura articulada de Batman con accesorios",
            price: 120.00,
            imageURL: "https://picsum.photos/seed/batman/400/400",
            sellerName: "dc_comics_pro",
            sellerProfileImage: "https://picsum.photos/seed/seller8/100/100",
            category: .movies,
            condition: .good,
            location: "Valencia",
            isFeatured: true,
            createdAt: Date().addingTimeInterval(-28800)
        )
    ]
}

