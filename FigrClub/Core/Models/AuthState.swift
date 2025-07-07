//
//  AuthState.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

enum AuthState: Equatable {
    case loading
    case authenticated(User)
    case unauthenticated
    case error(Error)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.unauthenticated, .unauthenticated):
            return true
        case let (.authenticated(user1), .authenticated(user2)):
            return user1.id == user2.id
        case let (.error(error1), .error(error2)):
            return error1.localizedDescription == error2.localizedDescription
        default:
            return false
        }
    }
}
