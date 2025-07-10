//
//  UIApplication+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import UIKit

extension UIApplication {
    /// Get the current key window
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// Get the top-most view controller
    var topViewController: UIViewController? {
        keyWindow?.rootViewController?.topViewController
    }
}
