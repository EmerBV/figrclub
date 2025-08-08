//
//  StoryCarousel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 8/8/25.
//

import SwiftUI
import Kingfisher

struct StoryCarousel: View {
    let imageURLs: [String]
    let onImageTap: (Int) -> Void
    
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                    KFImage(URL(string: imageURL))
                        .storyImageStyle()
                        .onTapGesture {
                            onImageTap(index)
                        }
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Indicador minimalista para stories
            if imageURLs.count > 1 {
                VStack {
                    HStack(spacing: 4) {
                        ForEach(0..<imageURLs.count, id: \.self) { index in
                            Rectangle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(height: 2)
                                .animation(.easeInOut, value: currentIndex)
                        }
                    }
                    .padding(.horizontal, AppTheme.Padding.medium)
                    .padding(.top, AppTheme.Padding.medium)
                    
                    Spacer()
                }
            }
        }
    }
}
