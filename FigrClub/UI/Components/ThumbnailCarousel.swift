//
//  ThumbnailCarousel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 8/8/25.
//

import SwiftUI
import Kingfisher

struct ThumbnailCarousel: View {
    let imageURLs: [String]
    let thumbnailSize: CGFloat
    let onImageTap: (Int) -> Void
    
    @State private var currentIndex = 0
    
    init(imageURLs: [String], thumbnailSize: CGFloat = 100, onImageTap: @escaping (Int) -> Void) {
        self.imageURLs = imageURLs
        self.thumbnailSize = thumbnailSize
        self.onImageTap = onImageTap
    }
    
    var body: some View {
        ZStack {
            if imageURLs.count == 1 {
                // Thumbnail único
                KFImage(URL(string: imageURLs[0]))
                    .thumbnailStyle(size: thumbnailSize)
                    .onTapGesture {
                        onImageTap(0)
                    }
            } else {
                // Múltiples thumbnails
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                        KFImage(URL(string: imageURL))
                            .thumbnailStyle(size: thumbnailSize)
                            .onTapGesture {
                                onImageTap(index)
                            }
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Indicadores usando tus componentes
                ProximityPageIndicator(
                    totalCount: imageURLs.count,
                    currentIndex: currentIndex,
                    minimumCountToShow: 2
                )
                
                ImageCounterIndicator(
                    currentIndex: currentIndex,
                    totalCount: imageURLs.count,
                    minimumCountToShow: 3
                )
            }
        }
    }
}
