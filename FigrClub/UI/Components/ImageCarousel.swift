//
//  ImageCarousel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 8/8/25.
//

import SwiftUI
import Kingfisher

struct ImageCarousel: View {
    let imageURLs: [String]
    let aspectRatio: CGFloat?
    let contentMode: SwiftUI.ContentMode
    let maxImages: Int
    let cornerRadius: CGFloat
    let showPageIndicator: Bool
    let showCounter: Bool
    let pageIndicatorMinimum: Int
    let counterMinimum: Int
    let onImageTap: ((Int) -> Void)?
    let onImageDoubleTap: ((Int) -> Void)?
    let onImageLongPress: ((Int) -> Void)?
    let showProgressView: Bool
    
    @State private var currentIndex = 0
    
    /// Inicializador principal con todos los parámetros personalizables
    init(
        imageURLs: [String],
        aspectRatio: CGFloat? = 1.0,
        contentMode: SwiftUI.ContentMode = .fill,
        maxImages: Int = 10,
        cornerRadius: CGFloat = 0,
        showPageIndicator: Bool = true,
        showCounter: Bool = true,
        pageIndicatorMinimum: Int = 2,
        counterMinimum: Int = 4,
        showProgressView: Bool = true,
        onImageTap: ((Int) -> Void)? = nil,
        onImageDoubleTap: ((Int) -> Void)? = nil,
        onImageLongPress: ((Int) -> Void)? = nil
    ) {
        self.imageURLs = imageURLs
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.maxImages = maxImages
        self.cornerRadius = cornerRadius
        self.showPageIndicator = showPageIndicator
        self.showCounter = showCounter
        self.pageIndicatorMinimum = pageIndicatorMinimum
        self.counterMinimum = counterMinimum
        self.showProgressView = showProgressView
        self.onImageTap = onImageTap
        self.onImageDoubleTap = onImageDoubleTap
        self.onImageLongPress = onImageLongPress
    }
    
    // MARK: - Computed Properties
    
    var displayedImages: [String] {
        Array(imageURLs.prefix(maxImages))
    }
    
    var hasImages: Bool {
        !displayedImages.isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        if hasImages {
            ZStack {
                // Carousel principal
                carouselContent
                
                // Indicadores de página
                if showPageIndicator {
                    ProximityPageIndicator(
                        totalCount: displayedImages.count,
                        currentIndex: currentIndex,
                        minimumCountToShow: pageIndicatorMinimum
                    )
                }
                
                // Contador de imágenes
                if showCounter {
                    ImageCounterIndicator(
                        currentIndex: currentIndex,
                        totalCount: displayedImages.count,
                        minimumCountToShow: counterMinimum
                    )
                }
            }
        } else {
            // Vista de placeholder cuando no hay imágenes
            emptyState
        }
    }
    
    // MARK: - Subviews
    
    private var carouselContent: some View {
        Group {
            if displayedImages.count == 1 {
                // Imagen única (sin TabView para mejor rendimiento)
                singleImageView(imageURL: displayedImages[0], index: 0)
            } else {
                // Múltiples imágenes con TabView
                multipleImagesView
            }
        }
    }
    
    private func singleImageView(imageURL: String, index: Int) -> some View {
        KFImage(URL(string: imageURL))
            .placeholder {
                if showProgressView {
                    ImageLoadingPlaceholder(aspectRatio: aspectRatio)
                } else {
                    PostImagePlaceholder()
                }
            }
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .cornerRadius(cornerRadius)
            .contentShape(Rectangle())
            .onTapGesture {
                onImageTap?(index)
            }
            .onTapGesture(count: 2) {
                onImageDoubleTap?(index)
            }
            .onLongPressGesture {
                onImageLongPress?(index)
            }
    }
    
    private var multipleImagesView: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(displayedImages.enumerated()), id: \.offset) { index, imageURL in
                KFImage(URL(string: imageURL))
                    .placeholder {
                        if showProgressView {
                            ImageLoadingPlaceholder(aspectRatio: aspectRatio)
                        } else {
                            PostImagePlaceholder()
                        }
                    }
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onImageTap?(index)
                    }
                    .onTapGesture(count: 2) {
                        onImageDoubleTap?(index)
                    }
                    .onLongPressGesture {
                        onImageLongPress?(index)
                    }
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
    
    private var emptyState: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(aspectRatio ?? 1, contentMode: .fit)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No hay imágenes")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
    }
}

// MARK: - Extensiones para inicializadores de conveniencia
extension ImageCarousel {
    /// Inicializador básico - Solo URLs de imágenes
    static func basic(_ imageURLs: [String]) -> ImageCarousel {
        ImageCarousel(imageURLs: imageURLs)
    }
    
    /// Inicializador para posts (comportamiento original)
    static func forPost(
        imageURLs: [String],
        onDoubleTap: @escaping () -> Void
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            aspectRatio: 1.0,
            contentMode: SwiftUI.ContentMode.fill,
            showProgressView: true,
            onImageDoubleTap: { _ in onDoubleTap() }
        )
    }
    
    /// Inicializador para productos en marketplace
    static func forProduct(
        imageURLs: [String],
        onImageTap: @escaping (Int) -> Void
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            aspectRatio: 1.0,
            contentMode: SwiftUI.ContentMode.fill,
            showCounter: true,
            counterMinimum: 2,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador para galerías de perfil
    static func forProfile(
        imageURLs: [String],
        aspectRatio: CGFloat = 4/3,
        onImageTap: @escaping (Int) -> Void
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            aspectRatio: aspectRatio,
            contentMode: SwiftUI.ContentMode.fill,
            cornerRadius: 12,
            showCounter: false,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador para stories
    static func forStory(
        imageURLs: [String],
        onImageTap: @escaping (Int) -> Void
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            aspectRatio: 9/16,
            contentMode: SwiftUI.ContentMode.fill,
            cornerRadius: 16,
            showPageIndicator: false,
            showCounter: false,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador para thumbnails en marketplace
    static func forThumbnails(
        imageURLs: [String],
        onImageTap: @escaping (Int) -> Void
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            aspectRatio: 1.0,
            contentMode: SwiftUI.ContentMode.fill,
            cornerRadius: 8,
            showCounter: true,
            counterMinimum: 2,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador para banners usando el estilo banner de Kingfisher
    static func forBannerWithKingfisher(
        imageURLs: [String],
        height: CGFloat = 200
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            aspectRatio: CGFloat?.none,
            contentMode: SwiftUI.ContentMode.fill,
            showCounter: false,
            pageIndicatorMinimum: 2
        )
    }
    
    /// Inicializador sin indicadores (minimalista)
    static func minimal(
        _ imageURLs: [String],
        aspectRatio: CGFloat = 1.0,
        onImageTap: ((Int) -> Void)? = nil
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            aspectRatio: aspectRatio,
            contentMode: SwiftUI.ContentMode.fill,
            showPageIndicator: false,
            showCounter: false,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador con esquinas redondeadas
    static func rounded(
        _ imageURLs: [String],
        cornerRadius: CGFloat = 12,
        onImageTap: ((Int) -> Void)? = nil
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            cornerRadius: cornerRadius,
            onImageTap: onImageTap
        )
    }
}

// MARK: - Extensiones de conveniencia para usar los carruseles especializados
extension ImageCarousel {
    /// Inicializador usando thumbnailStyle de Kingfisher
    static func thumbnails(
        _ imageURLs: [String],
        size: CGFloat = 100,
        onImageTap: @escaping (Int) -> Void
    ) -> ThumbnailCarousel {
        ThumbnailCarousel(
            imageURLs: imageURLs,
            thumbnailSize: size,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador usando bannerImageStyle de Kingfisher
    static func banner(
        _ imageURLs: [String],
        height: CGFloat = 200,
        onImageTap: ((Int) -> Void)? = nil
    ) -> BannerCarousel {
        BannerCarousel(
            imageURLs: imageURLs,
            height: height,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador usando storyImageStyle de Kingfisher
    static func story(
        _ imageURLs: [String],
        onImageTap: @escaping (Int) -> Void
    ) -> StoryCarousel {
        StoryCarousel(
            imageURLs: imageURLs,
            onImageTap: onImageTap
        )
    }
    
    /// Inicializador sin ProgressView (usa placeholder personalizado)
    static func withCustomPlaceholder(
        imageURLs: [String],
        onImageTap: ((Int) -> Void)? = nil
    ) -> ImageCarousel {
        ImageCarousel(
            imageURLs: imageURLs,
            showProgressView: false,
            onImageTap: onImageTap
        )
    }
}

// MARK: - Preview para desarrollo
#Preview {
    ScrollView {
        VStack(spacing: 30) {
            // Carousel básico
            ImageCarousel.basic([
                "https://picsum.photos/400/400?random=1",
                "https://picsum.photos/400/400?random=2",
                "https://picsum.photos/400/400?random=3"
            ])
            
            // Carousel para producto
            ImageCarousel.forProduct(imageURLs: [
                "https://picsum.photos/400/400?random=4",
                "https://picsum.photos/400/400?random=5"
            ]) { index in
                print("Tapped image \(index)")
            }
            
            // Carousel minimalista
            ImageCarousel.minimal([
                "https://picsum.photos/300/200?random=6",
                "https://picsum.photos/300/200?random=7"
            ], aspectRatio: 3/2)
            
            // Carousel redondeado
            ImageCarousel.rounded([
                "https://picsum.photos/400/300?random=8"
            ], cornerRadius: 20)
        }
        .padding()
    }
}
