//
//  ProductDetailView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 6/8/25.
//

import SwiftUI
import Kingfisher
import MapKit

struct ProductDetailView: View {
    let product: MarketplaceProduct
    
    @Environment(\.localizationManager) private var localizationManager
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Estados locales
    @State private var products: [MarketplaceProduct] = sampleProducts
    @State private var isFavorite = false
    @State private var selectedImageIndex = 0
    @State private var showingImageViewer = false
    @State private var showingSellerProfile = false
    @State private var showingContactSeller = false
    @State private var showingReportProduct = false
    @State private var showingAllReviews = false
    @State private var quantity = 1
    @State private var region = MKCoordinateRegion()
    
    // Imágenes de ejemplo (en una app real, esto vendría del producto)
    private var productImages: [String] {
        // Por ahora usamos la misma imagen, pero en una implementación real
        // el producto tendría múltiples imágenes
        [product.imageURL, product.imageURL, product.imageURL]
    }
    
    var body: some View {
        FigrNavigationStack {
            FigrVerticalScrollView {
                LazyVStack(spacing: 0) {
                    imageCarouselSection
                    productInfoSection
                    sellerInfoSection
                    descriptionSection
                    shippingSection
                    locationMapSection
                    reviewsSection
                    similarProductsSection
                    reportProductSection
                }
            }
            .navigationBarHidden(false)
            .toolbar {
                // Botón de back customizado
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .themedTextColor(.primary)
                    }
                }
                
                // Botones de acción
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isFavorite.toggle()
                            }
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(isFavorite ? .red : .primary)
                        }
                        
                        Button {
                            shareProduct()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .themedTextColor(.primary)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
        .onAppear {
            setupMapLocation()
        }
        .sheet(isPresented: $showingSellerProfile) {
            if let seller = createSellerUser() {
                UserProfileDetailView(user: seller)
            }
        }
        .sheet(isPresented: $showingContactSeller) {
            ContactSellerView(product: product)
        }
        .sheet(isPresented: $showingImageViewer) {
            ImageViewerSheet(
                images: productImages,
                selectedIndex: $selectedImageIndex
            )
        }
        .sheet(isPresented: $showingAllReviews) {
            AllReviewsView(product: product)
        }
        .sheet(isPresented: $showingReportProduct) {
            ReportProductSheet(product: product)
        }
    }
    
    // MARK: - Image Carousel Section
    private var imageCarouselSection: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(productImages.enumerated()), id: \.offset) { index, imageURL in
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .clipped()
                    .onTapGesture {
                        showingImageViewer = true
                    }
                    .tag(index)
            }
        }
        .frame(height: 400)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .overlay(alignment: .bottomTrailing) {
            Text("\(selectedImageIndex + 1)/\(productImages.count)")
                .font(.caption)
                .padding(.horizontal, AppTheme.Padding.small)
                .padding(.vertical, AppTheme.Padding.xSmall)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(AppTheme.Padding.medium)
        }
    }
    
    // MARK: - Product Info Section
    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(product.title)
                    .themedFont(.headlineLarge)
                    .themedTextColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(localizationManager.currencyString(from: product.price))
                    .themedFont(.displaySmall)
                    .foregroundColor(Color.figrBlueAccent)
                
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(product.condition.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Padding.medium)
                        .padding(AppTheme.Padding.smallPadding)
                        .background(
                            Capsule()
                                .fill(product.condition.color)
                        )
                    
                    Text(localizationManager.localizedString(for: product.category.localizedStringKey))
                        .font(.system(size: 12, weight: .medium))
                        .themedTextColor(.secondary)
                        .padding(.horizontal, AppTheme.Padding.medium)
                        .padding(.vertical, AppTheme.Padding.smallPadding)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                    
                    Spacer()
                }
            }
            
            Divider()
                .background(themeManager.currentBorderColor)
        }
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.vertical, AppTheme.Padding.medium)
    }
    
    // MARK: - Seller Info Section
    private var sellerInfoSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Button {
                showingSellerProfile = true
            } label: {
                HStack(spacing: AppTheme.Spacing.medium) {
                    KFImage(URL(string: product.sellerProfileImage))
                        .profileImageStyle(size: 50)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                        Text(product.sellerName)
                            .themedFont(.titleMedium)
                            .themedTextColor(.primary)
                        
                        HStack(spacing: AppTheme.Spacing.xxSmall) {
                            ForEach(0..<5) { index in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(index < 4 ? .yellow : .gray)
                            }
                            
                            Text("4.8")
                                .themedFont(.bodySmall)
                                .themedTextColor(.secondary)
                            
                            Text("(24 reseñas)")
                                .themedFont(.bodySmall)
                                .themedTextColor(.secondary)
                        }
                        
                        if let location = product.location {
                            Text(location)
                                .themedFont(.bodyXSmall)
                                .themedTextColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .themedTextColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .background(themeManager.currentBorderColor)
        }
        .padding(.horizontal, AppTheme.Padding.large)
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(localizationManager.localizedString(for: .productDescription))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            Text(product.description)
                .themedFont(.bodyMedium)
                .themedTextColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Divider()
                .background(themeManager.currentBorderColor)
        }
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.vertical, AppTheme.Padding.medium)
    }
    
    // MARK: - Shipping Section
    private var shippingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(localizationManager.localizedString(for: .shippingInfo))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: "truck.box")
                        .themedTextColor(.secondary)
                    Text(localizationManager.localizedString(for: .standardShipping))
                        .themedFont(.bodyMedium)
                        .themedTextColor(.primary)
                    Spacer()
                    Text("€5.99")
                        .themedFont(.bodyMedium)
                        .themedTextColor(.primary)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .themedTextColor(.secondary)
                    Text(localizationManager.localizedString(for: .estimatedDelivery))
                        .themedFont(.bodyMedium)
                        .themedTextColor(.primary)
                    Spacer()
                    Text("3-5 días")
                        .themedFont(.bodyMedium)
                        .themedTextColor(.secondary)
                }
            }
            
            Divider()
                .background(themeManager.currentBorderColor)
        }
        .padding(.horizontal, AppTheme.Padding.large)
    }
    
    // MARK: - Location Map Section
    private var locationMapSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(localizationManager.localizedString(for: .locationString))
                    .themedFont(.titleMedium)
                    .themedTextColor(.primary)
                
                Spacer()
                
                if let location = product.location {
                    Text(location)
                        .themedFont(.bodyMedium)
                        .themedTextColor(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.Padding.large)
            
            ProductLocationMapView(
                region: $region,
                locationName: product.location ?? localizationManager.localizedString(for: .locationString)
            )
            .frame(height: 100)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .padding(.horizontal, AppTheme.Padding.large)
            
            Divider()
                .background(themeManager.currentBorderColor)
                .padding(.horizontal, AppTheme.Padding.large)
        }
        .padding(.top, AppTheme.Padding.medium)
    }
    
    // MARK: - Reviews Section
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header con título y calificación general
            HStack {
                Text(localizationManager.localizedString(for: .reviewsTab))
                    .themedFont(.titleMedium)
                    .themedTextColor(.primary)
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("4.8")
                        .themedFont(.bodyMedium)
                        .themedTextColor(.primary)
                    
                    Text("(24)")
                        .themedFont(.bodySmall)
                        .themedTextColor(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.Padding.large)
            
            // Lista de 3 valoraciones
            ForEach(ProductDetailView.sampleReviews.prefix(3), id: \.id) { review in
                DetailReviewCard(review: review)
                    .padding(.horizontal, AppTheme.Padding.large)
                
                if review.id != ProductDetailView.sampleReviews.prefix(3).last?.id {
                    Divider()
                        .background(themeManager.currentBorderColor)
                        .padding(.horizontal, AppTheme.Padding.large)
                }
            }
            
            // Botón "Ver todas las valoraciones"
            if ProductDetailView.sampleReviews.count > 3 {
                Button {
                    showingAllReviews = true
                } label: {
                    HStack {
                        Text(localizationManager.localizedString(for: .seeAllReviews))
                            .themedFont(.titleMedium)
                            .themedTextColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .themedTextColor(.secondary)
                    }
                    .padding(.horizontal, AppTheme.Padding.large)
                    .padding(.vertical, AppTheme.Padding.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, AppTheme.Padding.large)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(themeManager.currentBorderColor)
                .padding(.horizontal, AppTheme.Padding.large)
        }
        .padding(.vertical, AppTheme.Padding.medium)
    }
    
    // MARK: - Similar Products Section
    private var similarProductsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(localizationManager.localizedString(for: .similarProducts))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
                .padding(.horizontal, AppTheme.Padding.large)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(products.prefix(5)) { similarProduct in
                        SimilarProductCard(product: similarProduct) {
                            // Navegar a otro producto similar
                            Logger.info("🛍️ Similar product tapped: \(similarProduct.title)")
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Padding.large)
            }
        }
        .padding(.top, AppTheme.Padding.medium)
        .padding(.bottom, AppTheme.Padding.xxLarge)
    }
    
    // MARK: - Report Product Section
    private var reportProductSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Divider()
                .background(themeManager.currentBorderColor)
                .padding(.horizontal, AppTheme.Padding.large)
            
            Button {
                showingReportProduct = true
            } label: {
                HStack {
                    Text(localizationManager.localizedString(for: .reportProduct))
                        .themedFont(.titleMedium)
                        .foregroundColor(.figrButtonBlueText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Padding.medium)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, AppTheme.Padding.medium)
        }
        .padding(.bottom, AppTheme.Padding.medium)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Button {
                showingContactSeller = true
            } label: {
                Text(localizationManager.localizedString(for: .contactSeller))
                    .themedFont(.titleMedium)
                    .foregroundColor(Color.figrBlueAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Padding.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(Color.figrBlueAccent, lineWidth: 1)
                    )
            }
            
            Button {
                // Acción de comprar
                buyProduct()
            } label: {
                Text(localizationManager.localizedString(for: .buyNow))
                    .themedFont(.titleMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Padding.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.figrBlueAccent)
                    )
            }
        }
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.vertical, AppTheme.Padding.medium)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Methods
    private func createSellerUser() -> User? {
        let randomId = Int.random(in: 1000...9999)
        let username = product.sellerName.lowercased().replacingOccurrences(of: " ", with: "_")
        
        return User(
            id: randomId,
            firstName: product.sellerName.components(separatedBy: " ").first ?? product.sellerName,
            lastName: product.sellerName.components(separatedBy: " ").dropFirst().joined(separator: " "),
            email: "\(username)@example.com",
            displayName: product.sellerName,
            fullName: product.sellerName,
            birthDate: nil,
            city: product.location?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines),
            country: product.location?.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: nil,
            preferredLanguage: "es",
            active: true,
            enabled: true,
            accountNonExpired: true,
            accountNonLocked: true,
            credentialsNonExpired: true,
            emailVerified: true,
            emailVerifiedAt: "2024-01-01T00:00:00.000Z",
            isVerified: Bool.random(),
            isPrivate: false,
            isPro: Bool.random(),
            canAccessProFeatures: Bool.random(),
            proSeller: Bool.random(),
            isActiveSellerProfile: true,
            isSellingActive: true,
            individualUser: true,
            admin: false,
            role: "USER",
            roleDescription: "Regular user",
            roleId: 1,
            hasProfileImage: true,
            hasCoverImage: Bool.random(),
            activeImageCount: Int.random(in: 0...10),
            followersCount: Int.random(in: 50...500),
            followingCount: Int.random(in: 20...200),
            postsCount: Int.random(in: 5...50),
            purchasesCount: Int.random(in: 0...20),
            createdAt: "2023-01-01T00:00:00.000Z",
            createdBy: nil,
            lastActivityAt: "2024-07-15T10:30:00.000Z",
            imageCapabilities: nil,
            maxProfileImageSizeMB: "5",
            maxCoverImageSizeMB: "10"
        )
    }
    
    private func setupMapLocation() {
        // Configurar coordenadas basadas en la ubicación del producto
        // En una implementación real, estas coordenadas vendrían del servidor
        let coordinates = getCoordinatesForLocation(product.location)
        region = MKCoordinateRegion(
            center: coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }
    
    private func getCoordinatesForLocation(_ location: String?) -> CLLocationCoordinate2D {
        // Mapeo de ubicaciones españolas a coordenadas
        // En una app real, esto se haría mediante geocoding
        let locationCoordinates: [String: CLLocationCoordinate2D] = [
            "Madrid": CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
            "Barcelona": CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
            "Valencia": CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
            "Sevilla": CLLocationCoordinate2D(latitude: 37.3886, longitude: -5.9823),
            "Bilbao": CLLocationCoordinate2D(latitude: 43.2627, longitude: -2.9253),
            "Zaragoza": CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891),
            "Málaga": CLLocationCoordinate2D(latitude: 36.7213, longitude: -4.4214)
        ]
        
        return locationCoordinates[location ?? "Madrid"] ?? CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038)
    }
    
    private func shareProduct() {
        Logger.info("🔗 Sharing product: \(product.title)")
        // Implementar share sheet
    }
    
    private func buyProduct() {
        Logger.info("🛒 Buy product: \(product.title)")
        // Implementar flujo de compra
    }
}

// MARK: - Product Location Map View
struct ProductLocationMapView: View {
    @Binding var region: MKCoordinateRegion
    let locationName: String
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [ProductLocationAnnotation(coordinate: region.center, name: locationName)]) { annotation in
            MapMarker(coordinate: annotation.coordinate, tint: .figrBlueAccent)
        }
        .disabled(true) // Hacer el mapa de solo lectura
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Product Location Annotation
struct ProductLocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}

// MARK: - Report Product Sheet
struct ReportProductSheet: View {
    let product: MarketplaceProduct
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    @State private var selectedReportReason: ReportReason?
    @State private var additionalComments = ""
    
    private let reportReasons: [ReportReason] = [
        .inappropriateContent,
        .scamOrFraud,
        .counterfeits,
        .incorrectInformation,
        .prohibitedItem,
        .other
    ]
    
    var body: some View {
        FigrNavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text(localizationManager.localizedString(for: .whatsTheProblem))
                        .themedFont(.titleMedium)
                        .themedTextColor(.primary)
                    
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(reportReasons, id: \.self) { reason in
                            ReportReasonRow(
                                reason: reason,
                                isSelected: selectedReportReason == reason
                            ) {
                                selectedReportReason = reason
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text(localizationManager.localizedString(for: .additionalComments))
                        .themedFont(.titleMedium)
                        .themedTextColor(.primary)
                    
                    TextEditor(text: $additionalComments)
                        .frame(minHeight: 100)
                        .padding(AppTheme.Padding.small)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding(AppTheme.Padding.large)
            .navigationTitle(localizationManager.localizedString(for: .reportProduct))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: .cancel)) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: .sendString)) {
                        submitReport()
                    }
                    .disabled(selectedReportReason == nil)
                }
            }
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReportReason else { return }
        
        Logger.info("🚨 Product reported: \(product.title), Reason: \(reason)")
        // Implementar envío de reporte
        
        dismiss()
    }
}

// MARK: - Review Model
struct ProductReview: Identifiable {
    let id = UUID()
    let userName: String
    let userImage: String
    let rating: Int
    let comment: String
    let date: Date
}

// MARK: - Review Card Component
struct DetailReviewCard: View {
    let review: ProductReview
    
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
                KFImage(URL(string: review.userImage))
                    .profileImageStyle(size: 40)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                    Text(review.userName)
                        .themedFont(.titleSmall)
                        .themedTextColor(.primary)
                        //.fontWeight(.medium)
                    
                    HStack(spacing: AppTheme.Spacing.xxSmall) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(index < review.rating ? .yellow : Color(.systemGray4))
                        }
                        
                        Text(dateFormatter.string(from: review.date))
                            .themedFont(.bodyXSmall)
                            .themedTextColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text(review.comment)
                .themedFont(.bodyMedium)
                .themedTextColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, AppTheme.Padding.small)
    }
}

// MARK: - Report Reason Row
struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(localizationManager.localizedString(for: reason.localizedStringKey))
                    .themedFont(.bodyMedium)
                    .themedTextColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .figrBlueAccent : .gray)
            }
            .padding(.vertical, AppTheme.Padding.small)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Report Reason Enum
enum ReportReason: CaseIterable {
    case inappropriateContent
    case scamOrFraud
    case counterfeits
    case incorrectInformation
    case prohibitedItem
    case other
    
    /*
    var displayName: String {
        switch self {
        case .inappropriateContent:
            return "Contenido inapropiado"
        case .scamOrFraud:
            return "Estafa o fraude"
        case .counterfeits:
            return "Producto falsificado"
        case .incorrectInformation:
            return "Información incorrecta"
        case .prohibitedItem:
            return "Artículo prohibido"
        case .other:
            return "Otro motivo"
        }
    }
     */
    
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .inappropriateContent:
            return .innapropriateContent
        case .scamOrFraud:
            return .scamOrFraud
        case .counterfeits:
            return .counterfeitProduct
        case .incorrectInformation:
            return .incorrectInformation
        case .prohibitedItem:
            return .prohibitedItem
        case .other:
            return .otherReason
        }
    }
}

// MARK: - Similar Product Card
struct SimilarProductCard: View {
    let product: MarketplaceProduct
    let action: () -> Void
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                KFImage(URL(string: product.imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipped()
                    .cornerRadius(AppTheme.CornerRadius.medium)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                    Text(product.title)
                        .font(.system(size: 12, weight: .medium))
                        .themedTextColor(.primary)
                        .lineLimit(2)
                        .frame(height: 28, alignment: .top)
                        .multilineTextAlignment(.leading)
                    
                    Text(localizationManager.currencyString(from: product.price))
                        .themedFont(.bodySmall)
                        .foregroundColor(Color.figrBlueAccent)
                }
            }
            .frame(width: 140)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Image Viewer Sheet
struct ImageViewerSheet: View {
    let images: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        FigrNavigationStack {
            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                    KFImage(URL(string: imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: .close)) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - All Reviews View
struct AllReviewsView: View {
    let product: MarketplaceProduct
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        FigrNavigationStack {
            FigrVerticalScrollView {
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    // Rating summary
                    VStack(spacing: AppTheme.Spacing.medium) {
                        HStack(spacing: AppTheme.Spacing.medium) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                                Text("4.8")
                                    .font(.largeTitle.weight(.bold))
                                    .themedTextColor(.primary)
                                
                                HStack(spacing: AppTheme.Spacing.xxSmall) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                
                                Text(localizationManager.localizedString(for: .basedOnString, arguments: 24))
                                    .themedFont(.bodySmall)
                                    .themedTextColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(themeManager.currentBorderColor)
                    }
                    .padding(.horizontal, AppTheme.Padding.large)
                    
                    // All reviews
                    ForEach(ProductDetailView.sampleReviews, id: \.id) { review in
                        DetailReviewCard(review: review)
                            .padding(.horizontal, AppTheme.Padding.large)
                        
                        if review.id != ProductDetailView.sampleReviews.last?.id {
                            Divider()
                                .background(themeManager.currentBorderColor)
                                .padding(.horizontal, AppTheme.Padding.large)
                        }
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(for: .allReviews))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: .close)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Contact Seller View
struct ContactSellerView: View {
    let product: MarketplaceProduct
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    @State private var message = ""
    
    var body: some View {
        FigrNavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Información del producto
                HStack(spacing: AppTheme.Spacing.medium) {
                    KFImage(URL(string: product.imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                        Text(product.title)
                            .themedFont(.titleSmall)
                            .themedTextColor(.primary)
                            .lineLimit(2)
                        
                        Text(localizationManager.currencyString(from: product.price))
                            .themedFont(.bodyMedium)
                            .foregroundColor(Color.figrBlueAccent)
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.Padding.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color(.systemGray6))
                )
                
                // Campo de mensaje
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(localizationManager.localizedString(for: .messageString))
                        .themedFont(.titleMedium)
                        .themedTextColor(.primary)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .padding(AppTheme.Padding.small)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding(AppTheme.Padding.large)
            .navigationTitle(localizationManager.localizedString(for: .contactSeller))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: .cancel)) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: .sendString)) {
                        sendMessage()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func sendMessage() {
        Logger.info("📤 Sending message to seller: \(product.sellerName)")
        // Implementar envío de mensaje
        dismiss()
    }
}

extension ProductDetailView {
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
            //isFeatured: true,
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
            //isFeatured: true,
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
            //isFeatured: false,
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
            //isFeatured: true,
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
            //isFeatured: false,
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
            //isFeatured: true,
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
            //isFeatured: false,
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
            //isFeatured: true,
            createdAt: Date().addingTimeInterval(-28800)
        )
    ]
}

// MARK: - Sample Reviews Data
extension ProductDetailView {
    static let sampleReviews: [ProductReview] = [
        ProductReview(
            userName: "María García",
            userImage: "https://picsum.photos/seed/user1/100/100",
            rating: 5,
            comment: "Excelente vendedor, producto en perfectas condiciones y envío rápido. Lo recomiendo totalmente.",
            date: Date().addingTimeInterval(-86400)
        ),
        ProductReview(
            userName: "Carlos López",
            userImage: "https://picsum.photos/seed/user2/100/100",
            rating: 4,
            comment: "Muy contento con la compra. La figura llegó bien empaquetada y en el estado descrito.",
            date: Date().addingTimeInterval(-172800)
        ),
        ProductReview(
            userName: "Ana Martín",
            userImage: "https://picsum.photos/seed/user3/100/100",
            rating: 5,
            comment: "Perfecta comunicación con el vendedor. La figura es exactamente como se veía en las fotos.",
            date: Date().addingTimeInterval(-259200)
        ),
        ProductReview(
            userName: "David Rodríguez",
            userImage: "https://picsum.photos/seed/user4/100/100",
            rating: 4,
            comment: "Buena calidad y precio justo. El envío tardó un poco más de lo esperado pero llegó bien.",
            date: Date().addingTimeInterval(-345600)
        ),
        ProductReview(
            userName: "Laura Fernández",
            userImage: "https://picsum.photos/seed/user5/100/100",
            rating: 5,
            comment: "¡Me encanta! Es mi segunda compra a este vendedor y siempre perfecto.",
            date: Date().addingTimeInterval(-432000)
        ),
        ProductReview(
            userName: "Miguel Santos",
            userImage: "https://picsum.photos/seed/user6/100/100",
            rating: 4,
            comment: "Producto como se describía. Vendedor serio y responsable.",
            date: Date().addingTimeInterval(-518400)
        ),
        ProductReview(
            userName: "Sofia Jiménez",
            userImage: "https://picsum.photos/seed/user7/100/100",
            rating: 5,
            comment: "Increíble atención al cliente. Resolvió todas mis dudas antes de la compra.",
            date: Date().addingTimeInterval(-604800)
        ),
        ProductReview(
            userName: "Pablo Moreno",
            userImage: "https://picsum.photos/seed/user8/100/100",
            rating: 3,
            comment: "El producto está bien, aunque tenía pequeños detalles que no se apreciaban en las fotos.",
            date: Date().addingTimeInterval(-691200)
        )
    ]
}

// MARK: - Preview
/*
 #Preview {
 ProductDetailView(product: sampleProducts[0])
 .environment(\.localizationManager, LocalizationManager())
 }
 */
