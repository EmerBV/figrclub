//
//  ViewState.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation
import SwiftUI

// MARK: - ViewState for UI Management
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case failure(NetworkError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var error: NetworkError? {
        if case .failure(let error) = self { return error }
        return nil
    }
    
    var data: T? {
        if case .success(let data) = self { return data }
        return nil
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Legacy ErrorHandler removed - use GlobalErrorHandler instead
