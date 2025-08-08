//
//  BannerCarousel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 8/8/25.
//

import SwiftUI
import Kingfisher

struct BannerCarousel: View {
    let imageURLs: [String]
    let height: CGFloat
    let onImageTap: ((Int) -> Void)?
    
    @State private var currentIndex = 0
    
    init(imageURLs: [String], height: CGFloat = 200, onImageTap: ((Int) -> Void)? = nil) {
        self.imageURLs = imageURLs
        self.height = height
        self.onImageTap = onImageTap
    }
    
    var body: some View {
        ZStack {
            if imageURLs.count == 1 {
                // Banner único
                KFImage(URL(string: imageURLs[0]))
                    .bannerImageStyle(height: height)
                    .onTapGesture {
                        onImageTap?(0)
                    }
            } else {
                // Múltiples banners
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                        KFImage(URL(string: imageURL))
                            .bannerImageStyle(height: height)
                            .onTapGesture {
                                onImageTap?(index)
                            }
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: height)
                
                // Indicadores para banners
                ProximityPageIndicator(
                    totalCount: imageURLs.count,
                    currentIndex: currentIndex,
                    minimumCountToShow: 2
                )
            }
        }
    }
}
