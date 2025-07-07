//
//  StorageAssembly.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import Swinject

final class StorageAssembly: Assembly {
    func assemble(container: Container) {
        // User Defaults Manager (if needed)
        container.register(UserDefaultsManagerProtocol.self) { _ in
            return UserDefaultsManager()
        }.inObjectScope(.container)
        
        // Core Data Stack (for future use)
        // container.register(CoreDataStack.self) { _ in
        //     return CoreDataStack.shared
        // }.inObjectScope(.container)
    }
}
