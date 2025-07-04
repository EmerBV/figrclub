//
//  AuthViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

final class AuthViewModel: ObservableObject {
    
    private let authRepository: AuthRepositoryProtocol
    
    init(
        authRepository: AuthRepositoryProtocol
    ) {
        self.authRepository = authRepository
    }
    
}
