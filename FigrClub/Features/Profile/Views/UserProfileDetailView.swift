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
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: ProfileTab = .onSale
    @State private var userProducts: [UserProduct] = []
    @State private var isLoading = false
    
    // Sample data - en un caso real vendría del servidor
    @State private var sampleProducts: [UserProduct] = UserProfileDetailView.generateSampleProducts()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header section
                    headerSection
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.large)
                    
                    // Tab selector
                    tabSelector
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.medium)
                    
                    // Content based on selected tab
                    tabContent
                        .padding(.horizontal, Spacing.large)
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
                    HStack(spacing: Spacing.medium) {
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
        VStack(spacing: Spacing.medium) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                // Profile image
                profileImageView
                
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    // Name
                    Text(user.displayName)
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)
                    
                    // Rating stars
                    HStack(spacing: Spacing.xxSmall) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        
                        Text("(\(user.followersCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // Statistics Row
            statisticsRow
            
            // Location
            locationView
        }
        .padding(.top, Spacing.medium)
    }
    
    // MARK: - Profile Image
    private var profileImageView: some View {
        let imageURL = URL(string: "http://localhost:8080/figrclub/api/v1/images/user/\(user.id)/profile")
        
        return Group {
            if user.hasProfileImage {
                KFImage(imageURL)
                    .setProcessor(
                        RoundCornerImageProcessor(cornerRadius: 45)
                        |> DownsamplingImageProcessor(size: CGSize(width: 180, height: 180))
                    )
                    .placeholder {
                        Circle()
                            .fill(themeManager.currentSecondaryTextColor.opacity(0.2))
                            .frame(width: 90, height: 90)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(themeManager.accentColor)
                            )
                    }
                    .onFailure { error in
                        Logger.warning("⚠️ Profile image failed to load: \(error.localizedDescription)")
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                    )
            }
        }
    }
    
    // MARK: - Statistics Row
    private var statisticsRow: some View {
        HStack(spacing: Spacing.large) {
            statisticItem(
                icon: "chart.bar.fill",
                value: "\(sampleProducts.filter { $0.status == .active }.count)",
                label: "Ventas"
            )
            
            statisticItem(
                icon: "bag.fill",
                value: "\(user.purchasesCount)",
                label: "Compras"
            )
            
            statisticItem(
                icon: "shippingbox.fill",
                value: "\(calculateTotalShipments())",
                label: "Envíos"
            )
        }
    }
    
    private func statisticItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Location View
    private var locationView: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundColor(.primary)
            
            Text("28033, Madrid.")
                .font(.body)
                .foregroundColor(.primary)
            
            Button("Ver mi ubicación") {
                // Acción para mostrar ubicación
            }
            .font(.body)
            .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: Spacing.xSmall) {
                        Text(tab.title)
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
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.medium), count: 2),
            spacing: Spacing.medium
        ) {
            ForEach(sampleProducts.filter { $0.status == .active }) { product in
                UserProductCard(product: product)
            }
        }
    }
    
    // MARK: - Reviews Content
    private var reviewsContent: some View {
        VStack(spacing: Spacing.large) {
            // Overall rating
            VStack(spacing: Spacing.medium) {
                Text("\(user.followersCount)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Valoraciones")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                HStack(spacing: Spacing.xxSmall) {
                    ForEach(0..<5) { index in
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(.vertical, Spacing.xLarge)
            
            // Individual reviews would go here
            Text("Las valoraciones aparecerán aquí")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.large)
        }
    }
    
    // MARK: - Info Content
    private var infoContent: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Información del perfil")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                InfoRow(title: "Miembro desde", value: "FigrClub desde \(extractYear(from: user.createdAt))")
                InfoRow(title: "Última conexión", value: user.lastActivityAt ?? "Hace poco")
                InfoRow(title: "Tiempo de respuesta", value: "Menos de 1 hora")
                InfoRow(title: "Idiomas", value: "Español")
            }
            
            Spacer(minLength: Spacing.xLarge)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserProducts() {
        // En un caso real, aquí se cargarían los productos del usuario desde el servidor
        userProducts = sampleProducts
    }
    
    private func calculateTotalShipments() -> Int {
        return sampleProducts.filter { $0.status == .sold }.count
    }
    
    private func extractYear(from dateString: String) -> String {
        let components = dateString.components(separatedBy: "-")
        return components.first ?? "2025"
    }
}

// MARK: - Profile Tab Enum
enum ProfileTab: CaseIterable {
    case onSale
    case reviews
    case info
    
    var title: String {
        switch self {
        case .onSale: return "En venta"
        case .reviews: return "Valoraciones"
        case .info: return "Info"
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
                                    Text("Inactivo")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("\(Int(product.price)) €")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                
                Text(product.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.small)
            
            // Featured Button
            if product.status == .active {
                Button("Destácalo ya") {
                    // Acción para destacar producto
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.blue)
                .padding(.vertical, Spacing.xSmall)
                .padding(.horizontal, Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity)
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
        .padding(.vertical, Spacing.xSmall)
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
