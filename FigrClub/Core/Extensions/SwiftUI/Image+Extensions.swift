//
//  Image+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 31/7/25.
//

import SwiftUI

extension Image {
    func figrIcon(size: CGFloat = AppTheme.IconSize.medium) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
    
    func figrProfileImage(size: CGFloat = 50) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.figrBorder, lineWidth: 1)
            )
    }
    
    func figrProductImage(cornerRadius: CGFloat = AppTheme.CornerRadius.image) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.figrBorder.opacity(0.3), lineWidth: 0.5)
            )
    }
}
