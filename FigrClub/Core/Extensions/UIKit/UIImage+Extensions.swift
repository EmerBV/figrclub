//
//  UIImage+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import UIKit

extension UIImage {
    /// Resize image to specified size
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Compress image to specified quality
    func compressed(quality: CGFloat = 0.8) -> Data? {
        return jpegData(compressionQuality: quality)
    }
    
    /// Create thumbnail
    func thumbnail(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        return resized(to: size)
    }
}
