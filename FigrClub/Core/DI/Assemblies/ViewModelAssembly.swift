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
        container.register(InputValidatorProtocol.self) { _ in
            InputValidator()
        }.inObjectScope(.container)
    }
}
