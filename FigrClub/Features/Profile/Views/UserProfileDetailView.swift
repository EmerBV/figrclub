//
//  UserProfileDetailView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/7/25.
//

import SwiftUI
import Kingfisher

struct UserProfileDetailView: View {
    let user: User
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var selectedTab: ProfileTab = .onSale
    @State private var userProducts: [UserProduct] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory = .all
    
    // Sample data - en un caso real vendría del servidor
    @State private var sampleProducts: [UserProduct] = UserProfileDetailView.generateSampleProducts()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header section
                    headerSection
                        .padding(.bottom, AppTheme.Spacing.large)
                    
                    // Tab selector
                    tabSelector
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.bottom, AppTheme.Spacing.medium)
                    
                    // Content based on selected tab
                    tabContent
                        .padding(.horizontal, AppTheme.Spacing.large)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Button(action: { /* Editar perfil */ }) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: { /* Compartir perfil */ }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .themedBackground()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            loadUserProducts()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            // Imagen de fondo
            backgroundImageView
            
            // Contenido principal
            VStack(spacing: AppTheme.Spacing.medium) {
                // Primera fila: información del usuario y foto de perfil
                HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                    // Información del usuario (lado izquierdo)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        // Información básica
                        userInfoSection
                        
                        // Estadísticas en VStack
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            statisticsRow
                        }
                        
                        // Ubicación
                        locationView
                    }
                    
                    Spacer()
                    
                    // Imagen de perfil (lado derecho, más pequeña)
                    profileImageView
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .frame(height: 220) // Altura fija para el header con fondo
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Background Image View
    private var backgroundImageView: some View {
        // Puedes usar una imagen específica del usuario o una imagen por defecto
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Opcional: Imagen de fondo real si tienes una URL
                AsyncImage(url: URL(string: "https://picsum.photos/800/400")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    // Fallback al gradiente si no hay imagen
                    EmptyView()
                }
                    .opacity(0.15) // Baja opacidad para no interferir con el texto
            )
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            // Nombre
            Text(user.displayName)
                .font(.title.weight(.bold))
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            // Rating stars
            HStack(spacing: AppTheme.Spacing.xxSmall) {
                ForEach(0..<5) { index in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                Text("(\(user.followersCount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Profile Image
    private var profileImageView: some View {
        let imageURL = URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(user.id)/profile")
        
        return Group {
            if user.hasProfileImage {
                KFImage(imageURL)
                    .setProcessor(
                        RoundCornerImageProcessor(cornerRadius: 30)
                        |> DownsamplingImageProcessor(size: CGSize(width: 120, height: 120))
                    )
                    .placeholder {
                        Circle()
                            .fill(themeManager.currentSecondaryTextColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(themeManager.accentColor)
                            )
                    }
                    .onFailure { error in
                        Logger.warning("⚠️ Profile image failed to load: \(error.localizedDescription)")
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Statistics Row
    private var statisticsRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(spacing: AppTheme.Spacing.large) {
                statisticItem(
                    icon: "chart.bar.fill",
                    value: "\(sampleProducts.filter { $0.status == .active }.count)",
                    label: localizationManager.localizedString(for: .salesString)
                )
                
                statisticItem(
                    icon: "bag.fill",
                    value: "\(user.purchasesCount)",
                    label: localizationManager.localizedString(for: .shoppingsString)
                )
                
                Spacer()
            }
            
            statisticItem(
                icon: "shippingbox.fill",
                value: "\(calculateTotalShipments())",
                label: localizationManager.localizedString(for: .shippingString)
            )
        }
    }
    
    private func statisticItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
    }
    
    // MARK: - Location View
    private var locationView: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            Text("28033, \(user.city ?? localizationManager.localizedString(for: .notSpecified)).")
                .font(.body)
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            Button(localizationManager.localizedString(for: .seeLocationString)) {
                // Acción para mostrar ubicación
            }
            .font(.body)
            .foregroundColor(.blue)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            //Spacer()
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: AppTheme.Spacing.xSmall) {
                        Text(localizationManager.localizedString(for: tab.localizedStringKey))
                            .font(.body.weight(selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        if selectedTab == tab {
                            Rectangle()
                                .fill(themeManager.accentColor)
                                .frame(height: 2)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .onSale:
            onSaleContent
        case .reviews:
            reviewsContent
        case .info:
            infoContent
        }
    }
    
    // MARK: - On Sale Content
    private var onSaleContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Search Section
            searchSection
            
            // Categories Section
            categoriesSection
            
            // Products Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
                GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
            ], spacing: AppTheme.Spacing.medium) {
                ForEach(filteredProducts) { product in
                    UserProductCard(product: product)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredProducts: [UserProduct] {
        let activeProducts = sampleProducts.filter { $0.status == .active }
        
        return activeProducts.filter { product in
            let matchesSearch = searchText.isEmpty ||
            product.title.localizedCaseInsensitiveContains(searchText)
            
            // Por ahora, asumimos que todos los productos coinciden con la categoría
            // En una implementación real, UserProduct tendría una propiedad category
            let matchesCategory = selectedCategory == .all
            
            return matchesSearch && matchesCategory
        }
    }
    
    // MARK: - Reviews Content
    private var reviewsContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Rating summary
            HStack(spacing: AppTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("4.8")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: AppTheme.Spacing.xxSmall) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(localizationManager.localizedString(for: .basedOnString, arguments: 24))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, AppTheme.Spacing.medium)
            
            // Sample reviews
            ForEach(0..<3) { index in
                ReviewCard(
                    userName: "Usuario \(index + 1)",
                    rating: Int.random(in: 4...5),
                    comment: "Excelente vendedor, producto en perfectas condiciones y envío rápido.",
                    date: Date().addingTimeInterval(-Double.random(in: 86400...2592000))
                )
            }
        }
    }
    
    // MARK: - Info Content
    private var infoContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            // Información personal
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text(localizationManager.localizedString(for: .profileInfo))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: AppTheme.Spacing.small) {
                    InfoRow(title: localizationManager.localizedString(for: .memberSince), value: createdAt(from: user.createdAt))
                    InfoRow(title: localizationManager.localizedString(for: .lastActivity), value: user.lastActivityAt ?? "")
                    InfoRow(title: localizationManager.localizedString(for: .locationString), value: user.city ?? localizationManager.localizedString(for: .notSpecified))
                    InfoRow(title: localizationManager.localizedString(for: .language), value: user.preferredLanguage ?? "")
                }
            }
            
            // Estadísticas de venta
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text(localizationManager.localizedString(for: .salesStatistics))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: AppTheme.Spacing.small) {
                    InfoRow(title: localizationManager.localizedString(for: .productsSold), value: "\(sampleProducts.filter { $0.status == .sold }.count)")
                    InfoRow(title: localizationManager.localizedString(for: .activeProducts), value: "\(sampleProducts.filter { $0.status == .active }.count)")
                    InfoRow(title: localizationManager.localizedString(for: .averageRating), value: "4.8 ⭐")
                }
            }
            
            // Política de devoluciones
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text(localizationManager.localizedString(for: .returnPolicy))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(localizationManager.localizedString(for: .returnPolicyDescription))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            
            // Botón de contacto
            if user.id != getCurrentUserId() { // Asumiendo que tienes una función para obtener el ID del usuario actual
                Button(action: { /* Acción de contacto */ }) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.body)
                        
                        Text(localizationManager.localizedString(for: .contactButton))
                            .font(.body.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.medium)
                    .background(themeManager.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, AppTheme.Spacing.small)
            } else {
                // Espacio vacío para mantener consistencia cuando no hay botón
                Spacer()
                    .frame(height: 32)
                    .padding(.top, AppTheme.Spacing.small)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.secondary)
            
            TextField(localizationManager.localizedString(for: .searchTextfield), text: $searchText)
                .font(.body)
                .foregroundColor(.primary)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
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
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, AppTheme.Spacing.large)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserProducts() {
        isLoading = true
        // Simular carga de datos
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            userProducts = sampleProducts
            isLoading = false
        }
    }
    
    private func getCurrentUserId() -> Int {
        // Implementar lógica para obtener el ID del usuario actual
        return 0
    }
    
    private func createdAt(from dateString: String) -> String {
        let components = dateString.components(separatedBy: "-")
        return components.first ?? "2025"
    }
    
    private func calculateTotalShipments() -> Int {
        return sampleProducts.filter { $0.status == .sold }.count
    }
    
}

// MARK: - Review Card Component
struct ReviewCard: View {
    let userName: String
    let rating: Int
    let comment: String
    let date: Date
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(userName)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.xxSmall) {
                    ForEach(0..<5) { index in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(index < rating ? .yellow : Color.gray.opacity(0.3))
                    }
                }
            }
            
            Text(comment)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(dateFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.accentColor)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Profile Tab Enum
enum ProfileTab: CaseIterable {
    case onSale
    case reviews
    case info
    
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .onSale: return .onSaleTab
        case .reviews: return .reviewsTab
        case .info: return .infoTab
        }
    }
}

// MARK: - User Product Model
struct UserProduct: Identifiable {
    let id = UUID()
    let title: String
    let price: Double
    let imageURL: String
    let status: ProductStatus
    let createdAt: Date
    let isFeatured: Bool
    
    enum ProductStatus {
        case active
        case sold
        case inactive
        case pending
    }
}

// MARK: - User Product Card
struct UserProductCard: View {
    let product: UserProduct
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Product Image
            KFImage(URL(string: product.imageURL))
                .placeholder {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 160)
                        .overlay(
                            ProgressView()
                                .tint(themeManager.accentColor)
                        )
                }
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    // Status overlay
                    Group {
                        if product.status == .inactive {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                                .overlay(
                                    Text(localizationManager.localizedString(for: .inactiveString))
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("\(Int(product.price)) €")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                
                Text(product.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 32) // Altura mínima para consistencia
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppTheme.Spacing.small)
            
            Spacer(minLength: 0)
            
            // Featured Button
            if product.status == .active {
                Button(localizationManager.localizedString(for: .highlightItNow)) {
                    // Acción para destacar producto
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.blue)
                .padding(.vertical, AppTheme.Spacing.xSmall)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .padding(.top, AppTheme.Spacing.small)
            } else {
                // Espacio vacío para mantener consistencia cuando no hay botón
                Spacer()
                    .frame(height: 32)
                    .padding(.top, AppTheme.Spacing.small)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
}

// MARK: - Sample Data Extension
extension UserProfileDetailView {
    static func generateSampleProducts() -> [UserProduct] {
        return [
            UserProduct(
                title: "Figura Toga Himiko 1/7 - My Hero Academia",
                price: 280,
                imageURL: "https://picsum.photos/seed/toga/400/400",
                status: .active,
                createdAt: Date(),
                isFeatured: false
            ),
            UserProduct(
                title: "Vitrina expositora negra - Mueble coleccionista",
                price: 180,
                imageURL: "https://picsum.photos/seed/vitrina/400/400",
                status: .active,
                createdAt: Date().addingTimeInterval(-3600),
                isFeatured: false
            ),
            UserProduct(
                title: "Figura Ichigo Bankai - Bleach",
                price: 225,
                imageURL: "https://picsum.photos/seed/ichigo/400/400",
                status: .active,
                createdAt: Date().addingTimeInterval(-7200),
                isFeatured: false
            ),
            UserProduct(
                title: "Set Naruto Team 7 - Completo",
                price: 150,
                imageURL: "https://picsum.photos/seed/naruto/400/400",
                status: .inactive,
                createdAt: Date().addingTimeInterval(-10800),
                isFeatured: false
            ),
            UserProduct(
                title: "Goku Ultra Instinct - Dragon Ball",
                price: 95,
                imageURL: "https://picsum.photos/seed/goku/400/400",
                status: .sold,
                createdAt: Date().addingTimeInterval(-14400),
                isFeatured: false
            ),
            UserProduct(
                title: "Demon Slayer Tanjiro - Efectos de agua",
                price: 75,
                imageURL: "https://picsum.photos/seed/tanjiro/400/400",
                status: .active,
                createdAt: Date().addingTimeInterval(-18000),
                isFeatured: false
            )
        ]
    }
}
