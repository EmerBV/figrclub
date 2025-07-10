//
//  UIViewController+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import UIKit

extension UIViewController {
    /// Get the top-most view controller
    var topViewController: UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topViewController
        }
        
        if let navigationController = self as? UINavigationController,
           let topViewController = navigationController.topViewController {
            return topViewController.topViewController
        }
        
        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topViewController
        }
        
        return self
    }
}
