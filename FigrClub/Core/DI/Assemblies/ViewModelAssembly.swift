//
//  ViewModelAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class ViewModelAssembly: Assembly {
    func assemble(container: Container) {
        // Register other ViewModels here as they are created
        // Example:
        // container.register(FeedViewModel.self) { resolver in
        //     // Dependencies
        //     return FeedViewModel(...)
        // }.inObjectScope(.transient)
    }
}

