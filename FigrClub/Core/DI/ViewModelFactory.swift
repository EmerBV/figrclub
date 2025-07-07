//
//  ViewModelFactory.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation
import SwiftUI

/// Factory para crear ViewModels usando dependency injection
@MainActor
final class ViewModelFactory {
    static let shared = ViewModelFactory()
    private let dependencyInjector = DependencyInjector.shared
    
    private init() {}
    
    // MARK: - Auth ViewModels
    func makeLoginViewModel() -> AuthViewModel {
        return dependencyInjector.makeAuthViewModel()
    }
}

// MARK: - SwiftUI Environment Integration
extension View {
    func withDependencyInjection() -> some View {
        self.environmentObject(DependencyInjector.shared.resolve(AuthViewModel.self))
    }
}
